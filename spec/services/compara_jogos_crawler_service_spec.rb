require "rails_helper"

RSpec.describe ComparaJogosCrawlerService do
  let(:connection) { instance_double(Faraday::Connection) }

  subject(:service) { described_class.new(connection: connection) }

  def gql_entry(name:, slug: nil, type: "game", min_price_new: 189.90, new_count: 3, publishers: [])
    {
      "id"            => 1,
      "min_price_new" => min_price_new,
      "new_count"     => new_count,
      "product"       => {
        "id"         => 1,
        "name"       => name,
        "slug"       => slug || name.downcase.tr(" ", "-"),
        "type"       => type,
        "publishers" => publishers
      }
    }
  end

  def gql_body(entries)
    { "data" => { "product_price" => entries } }.to_json
  end

  def gql_error_body(message)
    { "errors" => [{ "message" => message }] }.to_json
  end

  def stub_post(body, status: 200)
    req = double("faraday_request", headers: {})
    allow(req).to receive(:body=)
    response = instance_double(Faraday::Response, status: status, body: body)
    allow(connection).to receive(:post).and_yield(req).and_return(response)
    req
  end

  describe "#call" do
    context "with a single matching base game" do
      before do
        stub_post(gql_body([
          gql_entry(name: "Terra Mystica", slug: "terra-mystica", type: "game",
                    min_price_new: 189.90, new_count: 3)
        ]))
      end

      it "returns a Result struct" do
        expect(service.call("terra mystica")).to be_a(described_class::Result)
      end

      it "sets canonical_name" do
        expect(service.call("terra mystica").canonical_name).to eq("Terra Mystica")
      end

      it "converts min_price_new (BRL float) to integer cents" do
        expect(service.call("terra mystica").price_cents).to eq(18990)
      end

      it "maps API type 'game' to category 'boardgame_base'" do
        expect(service.call("terra mystica").category).to eq("boardgame_base")
      end

      it "defaults language to pt-BR" do
        expect(service.call("terra mystica").language).to eq("pt-BR")
      end

      it "returns empty aliases" do
        expect(service.call("terra mystica").aliases).to eq([])
      end
    end

    context "with a matching expansion" do
      before do
        stub_post(gql_body([
          gql_entry(name: "Terra Mystica: Fogo & Gelo", type: "expansion", min_price_new: 97.32)
        ]))
      end

      it "maps API type 'expansion' to category 'expansion'" do
        expect(service.call("terra mystica fogo gelo", type: "expansion").category).to eq("expansion")
      end
    end

    describe "type filtering" do
      it "sends type variable 'game' by default (boardgame_base)" do
        req = stub_post(gql_body([]))
        service.call("azul")
        expect(req).to have_received(:body=).with(include('"game"'))
      end

      it "sends type variable 'game' when type: 'boardgame_base'" do
        req = stub_post(gql_body([]))
        service.call("azul", type: "boardgame_base")
        expect(req).to have_received(:body=).with(include('"game"'))
      end

      it "sends type variable 'expansion' when type: 'expansion'" do
        req = stub_post(gql_body([]))
        service.call("azul", type: "expansion")
        expect(req).to have_received(:body=).with(include('"expansion"'))
      end

      it "falls back to 'game' for an unrecognised type" do
        req = stub_post(gql_body([]))
        service.call("azul", type: "unknown_type")
        expect(req).to have_received(:body=).with(include('"game"'))
      end
    end

    it "builds the correct _ilike pattern for multi-word queries" do
      req = stub_post(gql_body([]))
      service.call("terra mystica")
      expect(req).to have_received(:body=).with(include("%terra%mystica%"))
    end

    context "when multiple valid results are returned" do
      before do
        stub_post(gql_body([
          gql_entry(name: "Azul: Summer Pavilion", min_price_new: 59.90,  new_count: 2),
          gql_entry(name: "Azul",                  min_price_new: 149.00, new_count: 5)
        ]))
      end

      it "selects the alphabetically first product name" do
        expect(service.call("azul").canonical_name).to eq("Azul")
      end
    end

    context "when query is blank" do
      it "returns nil without making any HTTP request" do
        expect(connection).not_to receive(:post)
        expect(service.call("   ")).to be_nil
      end
    end

    context "when all entries have min_price_new == 0" do
      before { stub_post(gql_body([gql_entry(name: "No Price Game", min_price_new: 0)])) }

      it "returns nil" do
        expect(service.call("no price game")).to be_nil
      end
    end

    context "when the API returns an empty product_price list" do
      before { stub_post(gql_body([])) }

      it "returns nil" do
        expect(service.call("nonexistent")).to be_nil
      end
    end

    context "when HTTP returns a non-200 status" do
      before { stub_post("", status: 503) }

      it "returns nil" do
        allow(Rails.logger).to receive(:error)
        expect(service.call("azul")).to be_nil
      end

      it "logs an HttpError" do
        allow(Rails.logger).to receive(:error)
        service.call("azul")
        expect(Rails.logger).to have_received(:error).with(/HttpError/)
      end
    end

    context "when the response body contains GraphQL errors" do
      before { stub_post(gql_error_body("field not found")) }

      it "returns nil" do
        allow(Rails.logger).to receive(:error)
        expect(service.call("azul")).to be_nil
      end

      it "logs a ParseError" do
        allow(Rails.logger).to receive(:error)
        service.call("azul")
        expect(Rails.logger).to have_received(:error).with(/ParseError/)
      end
    end

    context "when the response body is invalid JSON" do
      before { stub_post("not-json-at-all") }

      it "returns nil" do
        allow(Rails.logger).to receive(:error)
        expect(service.call("azul")).to be_nil
      end
    end
  end

  describe "publisher extraction" do
    def call_with_publishers(*names)
      publishers = names.map { |n| { "publisher" => { "name" => n } } }
      stub_post(gql_body([gql_entry(name: "Azul", publishers: publishers)]))
      service.call("azul")
    end

    it "returns nil when the publishers list is empty" do
      stub_post(gql_body([gql_entry(name: "Azul", publishers: [])]))
      expect(service.call("azul").publisher).to be_nil
    end

    it "returns the first publisher when none is Brazilian" do
      expect(call_with_publishers("Z-Man Games, Inc.", "Asmodee").publisher).to eq("Z-Man Games, Inc.")
    end

    it "recognises 'Devir' as a Brazilian publisher" do
      expect(call_with_publishers("Asmodee", "Devir Brasil").publisher).to eq("Devir Brasil")
    end

    it "recognises 'PaperGames' as a Brazilian publisher" do
      expect(call_with_publishers("Asmodee", "PaperGames").publisher).to eq("PaperGames")
    end
  end

  describe "edition extraction" do
    def call_with_name(name)
      stub_post(gql_body([gql_entry(name: name)]))
      service.call("x")
    end

    it "returns nil when no edition is present in the name" do
      expect(call_with_name("Terra Mystica").edition).to be_nil
    end

    it "extracts a Portuguese edition label" do
      expect(call_with_name("Catan 2ª Edição").edition).to eq("2ª Edição")
    end

    it "extracts an English edition label" do
      expect(call_with_name("Dominion 2nd Edition").edition).to eq("2nd Edition")
    end
  end
end
