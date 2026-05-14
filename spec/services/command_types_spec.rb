require "rails_helper"

RSpec.describe CommandTypes do
  describe "ADD_PATTERN" do
    it "matches add commands with query" do
      expect(described_class::ADD_PATTERN).to match("adicionar catan")
      expect(described_class::ADD_PATTERN).to match("add catan")
    end

    it "does not match command without query" do
      expect(described_class::ADD_PATTERN).not_to match("adicionar")
      expect(described_class::ADD_PATTERN).not_to match("add")
    end
  end

  describe "TRACK_PATTERN" do
    it "matches track commands" do
      expect(described_class::TRACK_PATTERN).to match("monitorar wingspan")
      expect(described_class::TRACK_PATTERN).to match("track wingspan")
    end
  end

  describe "DELETE_PATTERN" do
    it "matches delete commands" do
      expect(described_class::DELETE_PATTERN).to match("deletar catan")
      expect(described_class::DELETE_PATTERN).to match("delete catan")
    end
  end

  describe "HELP_PATTERN" do
    it "matches help-only commands" do
      expect(described_class::HELP_PATTERN).to match("ajuda")
      expect(described_class::HELP_PATTERN).to match("help")
      expect(described_class::HELP_PATTERN).to match("?")
    end

    it "does not match help with extra text" do
      expect(described_class::HELP_PATTERN).not_to match("help me")
    end
  end
end
