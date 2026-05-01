require "rails_helper"

RSpec.describe CommandTypes do
  describe "ADD_PATTERN" do
    it "matches add commands with query" do
      expect("adicionar catan").to match(described_class::ADD_PATTERN)
      expect("add catan").to match(described_class::ADD_PATTERN)
    end

    it "does not match command without query" do
      expect("adicionar").not_to match(described_class::ADD_PATTERN)
      expect("add").not_to match(described_class::ADD_PATTERN)
    end
  end

  describe "TRACK_PATTERN" do
    it "matches track commands" do
      expect("monitorar wingspan").to match(described_class::TRACK_PATTERN)
      expect("track wingspan").to match(described_class::TRACK_PATTERN)
    end
  end

  describe "DELETE_PATTERN" do
    it "matches delete commands" do
      expect("deletar catan").to match(described_class::DELETE_PATTERN)
      expect("delete catan").to match(described_class::DELETE_PATTERN)
    end
  end

  describe "HELP_PATTERN" do
    it "matches help-only commands" do
      expect("ajuda").to match(described_class::HELP_PATTERN)
      expect("help").to match(described_class::HELP_PATTERN)
      expect("?").to match(described_class::HELP_PATTERN)
    end

    it "does not match help with extra text" do
      expect("help me").not_to match(described_class::HELP_PATTERN)
    end
  end
end
