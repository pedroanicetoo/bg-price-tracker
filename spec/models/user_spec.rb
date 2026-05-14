require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:collection_items).dependent(:destroy) }
    it { is_expected.to have_many(:collected_products).through(:collection_items).source(:product) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:consent_status).in_array(User::CONSENT_STATUSES) }

    describe "phone format" do
      it "accepts valid E.164 format" do
        user.phone = "+5562999999999"
        expect(user).to be_valid
      end

      it "accepts nil phone (pre-consent)" do
        user.phone = nil
        user.consent_status = "pending"
        expect(user).to be_valid
      end

      it "rejects phone without leading +" do
        user.phone = "5562999999999"
        expect(user).not_to be_valid
      end

      it "rejects phone that is too short" do
        user.phone = "+123"
        expect(user).not_to be_valid
      end
    end

    describe "phone uniqueness" do
      it "rejects duplicate phones" do
        create(:user, phone: "+5562999999999")
        duplicate = build(:user, phone: "+5562999999999")
        expect(duplicate).not_to be_valid
      end

      it "allows multiple records with nil phone" do
        create(:user, :pending)
        user2 = build(:user, :pending)
        expect(user2).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:accepted_user) { create(:user, consent_status: "accepted") }
    let!(:pending_user)  { create(:user, :pending) }
    let!(:revoked_user)  { create(:user, :revoked) }

    describe ".accepted" do
      it "includes accepted users" do
        expect(described_class.accepted).to include(accepted_user)
      end

      it "excludes pending and revoked users" do
        expect(described_class.accepted).not_to include(pending_user, revoked_user)
      end
    end

    describe ".active" do
      it "includes accepted non-anonymized users" do
        expect(described_class.active).to include(accepted_user)
      end

      it "excludes revoked users" do
        expect(described_class.active).not_to include(revoked_user)
      end
    end
  end

  describe "#accepted?" do
    it "returns true when consent_status is accepted" do
      user.consent_status = "accepted"
      expect(user).to be_accepted
    end

    it "returns false for other statuses" do
      user.consent_status = "pending"
      expect(user).not_to be_accepted
    end
  end

  describe "#anonymized?" do
    it "returns false when anonymized_at is nil" do
      user.anonymized_at = nil
      expect(user).not_to be_anonymized
    end

    it "returns true when anonymized_at is set" do
      user.anonymized_at = Time.current
      expect(user).to be_anonymized
    end
  end

  describe "#anonymize!" do
    let!(:persisted_user) { create(:user, phone: "+5562987654321") }

    it "replaces phone with SHA256 hash prefixed by ANONIMIZADO_" do
      original_phone = persisted_user.phone
      persisted_user.anonymize!

      expect(persisted_user.reload.phone).to start_with("ANONIMIZADO_")
      expect(persisted_user.phone).not_to include(original_phone)
    end

    it "sets consent_status to revoked" do
      persisted_user.anonymize!
      expect(persisted_user.reload.consent_status).to eq("revoked")
    end

    it "sets anonymized_at timestamp" do
      persisted_user.anonymize!
      expect(persisted_user.reload.anonymized_at).to be_present
    end
  end
end
