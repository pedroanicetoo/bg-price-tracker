require "rails_helper"

RSpec.describe ProductSearchService do
  def mock_parser(result)
    instance_double(ComparaJogosCrawlerService).tap do |p|
      allow(p).to receive(:call).and_return(result)
    end
  end

  def parsed_result(canonical_name:, category: "boardgame_base", aliases: [])
    ComparaJogosCrawlerService::Result.new(
      canonical_name: canonical_name,
      publisher:      "Devir",
      edition:        nil,
      language:       "pt-BR",
      category:       category,
      aliases:        aliases
    )
  end

  before do
    create(:product, canonical_name: "Catan",   category: "boardgame_base",
                     aliases: ["Colonizadores de Catan", "Settlers of Catan"])
    create(:product, canonical_name: "Wingspan", category: "boardgame_base")
  end

  describe "when parser identifies an existing DB product" do
    it "returns the matching DB product" do
      results = described_class.new("catan", parser: mock_parser(parsed_result(canonical_name: "Catan"))).call
      expect(results.first.canonical_name).to eq("Catan")
      expect(results.first).to be_persisted
    end
  end

  describe "when parser identifies a product via alias" do
    it "finds product by slug derived from alias" do
      results = described_class.new(
        "colonizadores de catan",
        parser: mock_parser(parsed_result(canonical_name: "Catan", aliases: ["Colonizadores de Catan"]))
      ).call
      expect(results.first.canonical_name).to eq("Catan")
    end
  end

  describe "when parser identifies a product not yet in the DB" do
    it "returns a transient (unsaved) Product instance" do
      results = described_class.new("Brass Birmingham",
                  parser: mock_parser(parsed_result(canonical_name: "Brass: Birmingham"))).call
      expect(results.size).to eq(1)
      expect(results.first.canonical_name).to eq("Brass: Birmingham")
      expect(results.first).not_to be_persisted
    end

    it "keeps all aliases from parser result" do
      results = described_class.new(
        "Brass Birmingham",
        parser: mock_parser(
          parsed_result(canonical_name: "Brass: Birmingham", aliases: ["Brass", "Brass Birmingham"])
        )
      ).call

      expect(results.first.aliases).to eq(["Brass", "Brass Birmingham"])
    end
  end

  describe "when parser returns nil (not found)" do
    it "returns empty array" do
      results = described_class.new("XxZzUnknown", parser: mock_parser(nil)).call
      expect(results).to be_empty
    end
  end

  describe "when query is empty" do
    it "returns empty array without calling parser" do
      parser = instance_spy(ComparaJogosCrawlerService)
      result = described_class.new("  ", parser: parser).call
      expect(result).to be_empty
      expect(parser).not_to have_received(:call)
    end
  end
end
