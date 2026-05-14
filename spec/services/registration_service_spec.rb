require "rails_helper"

RSpec.describe RegistrationService do
  let(:phone) { "+5562999999999" }

  describe "#call" do
    context "when user does not exist yet" do
      let(:result) { described_class.new(phone: phone, text: "oi", profile_name: "Pedro").call }

      it "creates a pending user with the correct attributes" do
        expect { result }.to change(User, :count).by(1)
        created = User.order(:id).last
        expect(created.phone).to eq(phone)
        expect(created.consent_status).to eq("pending")
      end

      it "returns a welcome message" do
        expect(result.messages.first).to include("BG Price Tracker")
      end
    end

    context "when user exists and accepts consent" do
      let!(:user) { create(:user, :pending, phone: phone) }

      it "updates user to accepted and sets consent_at" do
        result = described_class.new(phone: phone, text: "sim", user: user, profile_name: "Pedro").call

        expect(user.reload.consent_status).to eq("accepted")
        expect(user.consent_at).to be_present
        expect(result.messages.first).to include("Tudo certo")
      end
    end

    context "when user exists and rejects consent" do
      let!(:user) { create(:user, :pending, phone: phone) }

      it "updates user to rejected" do
        result = described_class.new(phone: phone, text: "não", user: user, profile_name: "Pedro").call

        expect(user.reload.consent_status).to eq("rejected")
        expect(result.messages.first).to include("não será armazenado")
      end
    end

    context "when response is neither yes nor no" do
      let!(:user) { create(:user, :pending, phone: phone) }

      it "returns consent prompt and keeps pending status" do
        result = described_class.new(phone: phone, text: "talvez", user: user).call

        expect(user.reload.consent_status).to eq("pending")
        expect(result.messages.first).to include("Responda *SIM*")
      end
    end

    context "when create raises RecordNotUnique" do
      let!(:existing_user) { create(:user, :pending, phone: phone) }

      it "falls back to existing user and processes consent" do
        allow(User).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
        allow(User).to receive(:find_by!).with(phone: phone).and_return(existing_user)

        result = described_class.new(phone: phone, text: "sim", profile_name: "Pedro").call

        expect(existing_user.reload.consent_status).to eq("accepted")
        expect(result.messages.first).to include("Tudo certo")
      end
    end
  end
end
