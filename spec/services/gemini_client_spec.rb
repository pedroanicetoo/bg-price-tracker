require "rails_helper"

RSpec.describe GeminiClientService do
  let(:api_key) { "test-key" }
  let(:connection) { instance_double(Faraday::Connection) }

  def response(status:, body:)
    instance_double(Faraday::Response, status: status, body: body)
  end

  subject(:client) { described_class.new(api_key: api_key, connection: connection) }

  describe "#call" do
    context "on success (200)" do
      before do
        allow(connection).to receive(:post).and_return(
          response(status: 200, body: {
            "candidates" => [
              { "content" => { "parts" => [{ "text" => '{"canonical_name":"Catan"}' }] } }
            ]
          })
        )
      end

      it "returns a Response with text" do
        result = client.call(prompt: "test")
        expect(result).to be_a(GeminiClientService::Response)
        expect(result.text).to eq('{"canonical_name":"Catan"}')
      end

      it "posts to the model endpoint with prompt payload" do
        expect(connection).to receive(:post) do |path, body|
          payload = JSON.parse(body)
          expect(path).to include("/v1beta/models/")
          expect(path).to include(":generateContent")
          expect(path).to include("key=test-key")
          expect(payload.dig("contents", 0, "parts", 0, "text")).to eq("test")
        end.and_return(response(status: 200, body: {
          "candidates" => [
            { "content" => { "parts" => [{ "text" => "{}" }] } }
          ]
        }))

        client.call(prompt: "test")
      end
    end

    context "on quota exceeded (429)" do
      before do
        allow(connection).to receive(:post)
          .and_return(response(status: 429, body: { "error" => "quota exceeded" }))
      end

      it "raises QuotaError" do
        expect { client.call(prompt: "test") }.to raise_error(GeminiClientService::QuotaError)
      end
    end

    context "on API error (500)" do
      before do
        allow(connection).to receive(:post)
          .and_return(response(status: 500, body: { "error" => "internal" }))
      end

      it "raises ApiError" do
        expect { client.call(prompt: "test") }.to raise_error(GeminiClientService::ApiError)
      end
    end

    context "on unexpected response shape" do
      before do
        allow(connection).to receive(:post)
          .and_return(response(status: 200, body: { "candidates" => [] }))
      end

      it "raises ParseError" do
        expect { client.call(prompt: "test") }.to raise_error(GeminiClientService::ParseError)
      end
    end

    context "on invalid JSON body string" do
      before do
        allow(connection).to receive(:post)
          .and_return(response(status: 200, body: "{not-json"))
      end

      it "raises ParseError" do
        expect { client.call(prompt: "test") }.to raise_error(GeminiClientService::ParseError)
      end
    end
  end
end
