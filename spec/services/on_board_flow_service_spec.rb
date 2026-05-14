require "rails_helper"

RSpec.describe OnBoardFlowService do
  let(:user) { create(:user) }

  describe "#call" do
    context "when command is add" do
      let(:cmd_result) { AppendingCollectionService::Result.new(messages: ["ok"], done: true) }
      let(:service) { described_class.new(user: user, text: "adicionar catan") }

      it "delegates to AppendingCollectionService with extracted query" do
        appender = instance_double(AppendingCollectionService, call: cmd_result)
        allow(AppendingCollectionService).to receive(:new).with(user: user, query: "catan").and_return(appender)

        result = service.call

        expect(AppendingCollectionService).to have_received(:new).with(user: user, query: "catan")
        expect(result.messages).to eq(["ok"])
      end

      it "supports english add command" do
        appender = instance_double(AppendingCollectionService, call: cmd_result)
        english_service = described_class.new(user: user, text: "add wingspan")
        allow(AppendingCollectionService).to receive(:new).with(user: user, query: "wingspan").and_return(appender)

        result = english_service.call

        expect(AppendingCollectionService).to have_received(:new).with(user: user, query: "wingspan")
        expect(result.messages).to eq(["ok"])
      end
    end

    context "when command is help" do
      it "returns help message" do
        result = described_class.new(user: user, text: "ajuda").call

        expect(result.messages.first).to include("Comandos disponíveis")
        expect(result.messages.first).to include("adicionar")
      end
    end

    context "when command is unknown" do
      it "returns fallback message" do
        result = described_class.new(user: user, text: "qualquer coisa").call

        expect(result.messages.first).to include("Não entendi")
        expect(result.messages.first).to include("ajuda")
      end
    end
  end
end
