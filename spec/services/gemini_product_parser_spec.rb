require "rails_helper"

RSpec.describe GeminiProductParserService do
  def mock_client(text)
    instance_double(GeminiClientService).tap do |c|
      allow(c).to receive(:call).and_return(GeminiClientService::Response.new(text: text))
    end
  end

  subject(:parser) { described_class.new(client: client) }

  describe "#call" do
    context "with a valid board game response" do
      let(:client) do
        mock_client(<<~JSON)
          {
            "canonical_name": "Catan",
            "publisher": "Devir",
            "edition": null,
            "language": "pt-BR",
            "category": "boardgame_base",
            "price_cents": 15990,
            "aliases": ["Colonizadores de Catan", "Settlers of Catan"]
          }
        JSON
      end

      it "returns a Result with correct fields" do
        result = parser.call("Catan")
        expect(result).to be_a(GeminiProductParserService::Result)
        expect(result.canonical_name).to eq("Catan")
        expect(result.publisher).to eq("Devir")
        expect(result.category).to eq("boardgame_base")
        expect(result.aliases).to include("Settlers of Catan")
        expect(result.price_cents).to eq(15990)
      end

      it "is valid" do
        expect(parser.call("Catan")).to be_valid
      end
    end

    context "when the product is not found" do
      let(:client) { mock_client('{"error": "not_found"}') }

      it "returns nil" do
        expect(parser.call("XxUnknownGamexX")).to be_nil
      end
    end

    context "when model wraps JSON in markdown fences" do
      let(:client) do
        mock_client("```json\n{\"canonical_name\":\"Wingspan\",\"category\":\"boardgame_base\",\"aliases\":[]}\n```")
      end

      it "strips fences and parses correctly" do
        result = parser.call("Wingspan")
        expect(result&.canonical_name).to eq("Wingspan")
      end
    end

    context "when model returns malformed JSON" do
      let(:client) { mock_client("Sorry, I cannot help with that.") }

      it "returns nil" do
        expect(parser.call("Catan")).to be_nil
      end
    end

    context "when Gemini raises an error" do
      let(:client) do
        instance_double(GeminiClientService).tap do |c|
          allow(c).to receive(:call).and_raise(GeminiClientService::ApiError, "quota exceeded")
        end
      end

      it "returns nil without raising" do
        expect { parser.call("Catan") }.not_to raise_error
        expect(parser.call("Catan")).to be_nil
      end
    end

    context "with empty query" do
      let(:client) { instance_double(GeminiClientService) }

      it "returns nil without calling the API" do
        expect(client).not_to receive(:call)
        expect(parser.call("  ")).to be_nil
      end
    end
  end
end
