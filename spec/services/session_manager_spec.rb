require "rails_helper"

RSpec.describe SessionManagerService, type: :service do
  let(:redis_mock) { instance_double(Redis) }

  subject(:manager) { described_class.new(redis: redis_mock) }

  let(:phone) { "+5562999999999" }

  describe "#set" do
    it "stores the session with 30-minute TTL" do
      expect(redis_mock).to receive(:setex)
        .with("session:#{phone}", 30.minutes.to_i, anything)

      manager.set(phone, state: :consent_pending, data: { profile_name: "Test" })
    end

    it "serializes state as a string" do
      captured = nil
      allow(redis_mock).to receive(:setex) { |_k, _t, v| captured = v }

      manager.set(phone, state: :welcome)

      parsed = JSON.parse(captured)
      expect(parsed["state"]).to eq("welcome")
    end

    it "includes updated_at in the payload" do
      captured = nil
      allow(redis_mock).to receive(:setex) { |_k, _t, v| captured = v }

      manager.set(phone, state: :welcome)

      expect(JSON.parse(captured)).to have_key("updated_at")
    end

    it "stores arbitrary data hash" do
      captured = nil
      allow(redis_mock).to receive(:setex) { |_k, _t, v| captured = v }

      manager.set(phone, state: :categories, data: { categories: %w[expansion] })

      parsed = JSON.parse(captured)
      expect(parsed["data"]["categories"]).to eq(["expansion"])
    end
  end

  describe "#get" do
    context "when session exists" do
      before do
        payload = { state: "categories", data: { categories: [1] }, updated_at: Time.current.iso8601 }.to_json
        allow(redis_mock).to receive(:get).with("session:#{phone}").and_return(payload)
      end

      it "returns a symbolized hash" do
        result = manager.get(phone)
        expect(result[:state]).to eq("categories")
      end

      it "returns symbolized data" do
        result = manager.get(phone)
        expect(result[:data]).to be_a(Hash)
      end
    end

    context "when session does not exist" do
      before { allow(redis_mock).to receive(:get).with("session:#{phone}").and_return(nil) }

      it "returns nil" do
        expect(manager.get(phone)).to be_nil
      end
    end
  end

  # ── #clear ─────────────────────────────────────────────────────────────────

  describe "#clear" do
    it "deletes the session key from Redis" do
      expect(redis_mock).to receive(:del).with("session:#{phone}")
      manager.clear(phone)
    end
  end

  # ── #exists? ───────────────────────────────────────────────────────────────

  describe "#exists?" do
    it "returns true when session key exists" do
      allow(redis_mock).to receive(:exists?).with("session:#{phone}").and_return(true)
      expect(manager.exists?(phone)).to be true
    end

    it "returns false when session key does not exist" do
      allow(redis_mock).to receive(:exists?).with("session:#{phone}").and_return(false)
      expect(manager.exists?(phone)).to be false
    end
  end

  describe "nested helpers" do
    describe "#get_nested" do
      it "returns nested value from session data" do
        payload = { state: "active", data: { "foo" => "bar" }, updated_at: Time.current.iso8601 }.to_json
        allow(redis_mock).to receive(:get).with("session:#{phone}").and_return(payload)

        expect(manager.get_nested(phone, :foo)).to eq("bar")
      end

      it "returns nil when session does not exist" do
        allow(redis_mock).to receive(:get).with("session:#{phone}").and_return(nil)

        expect(manager.get_nested(phone, :foo)).to be_nil
      end
    end

    describe "#set_nested" do
      it "merges nested value into existing session data" do
        payload = { state: "categories", data: { "a" => 1 }, updated_at: Time.current.iso8601 }.to_json
        allow(redis_mock).to receive(:get).with("session:#{phone}").and_return(payload)

        captured = nil
        allow(redis_mock).to receive(:setex) { |_k, _t, v| captured = JSON.parse(v) }

        manager.set_nested(phone, :b, 2)

        expect(captured["state"]).to eq("categories")
        expect(captured["data"]).to include("a" => 1, "b" => 2)
      end
    end

    describe "#clear_nested" do
      it "removes nested keys from data" do
        payload = { state: "active", data: { "a" => 1, "b" => 2 }, updated_at: Time.current.iso8601 }.to_json
        allow(redis_mock).to receive(:get).with("session:#{phone}").and_return(payload)

        captured = nil
        allow(redis_mock).to receive(:setex) { |_k, _t, v| captured = JSON.parse(v) }

        manager.clear_nested(phone, :b)

        expect(captured["data"]).to eq({ "a" => 1 })
      end

      it "does nothing when session does not exist" do
        allow(redis_mock).to receive(:get).with("session:#{phone}").and_return(nil)
        expect(redis_mock).not_to receive(:setex)

        manager.clear_nested(phone, :x)
      end
    end
  end

  # ── Key isolation ──────────────────────────────────────────────────────────

  describe "key namespacing" do
    it "prefixes keys with 'session:'" do
      expect(redis_mock).to receive(:setex).with(start_with("session:"), anything, anything)
      manager.set(phone, state: :welcome)
    end

    it "uses different keys for different phones" do
      other_phone = "+5561888888888"
      keys = []
      allow(redis_mock).to receive(:setex) { |k, *_| keys << k }

      manager.set(phone, state: :welcome)
      manager.set(other_phone, state: :welcome)

      expect(keys.uniq.size).to eq(2)
    end
  end
end
