require "rails_helper"

RSpec.describe Product, type: :model do
  subject(:product) { build(:product, :catan) }

  describe "associations" do
    it { is_expected.to have_many(:collection_items) }
    it { is_expected.to have_many(:collectors).through(:collection_items).source(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:canonical_name) }
    it { is_expected.to validate_inclusion_of(:category).in_array(Product::CATEGORIES) }

    it "rejects duplicate slugs" do
      create(:product, :catan)
      duplicate = build(:product, canonical_name: "Catan")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end

    it "requires current_price_updated_at when price_cents is greater than zero" do
      priced = build(:product, price_cents: 1500, current_price_updated_at: nil)
      expect(priced).not_to be_valid
      expect(priced.errors[:current_price_updated_at]).to be_present
    end

    it "allows missing current_price_updated_at when price_cents is zero" do
      free = build(:product, price_cents: 0, current_price_updated_at: nil)
      expect(free).to be_valid
    end

    it "rejects negative price_cents" do
      invalid = build(:product, price_cents: -1)
      expect(invalid).not_to be_valid
      expect(invalid.errors[:price_cents]).to be_present
    end

    it "rejects negative estimated_price_cents" do
      invalid = build(:product, estimated_price_cents: -1)
      expect(invalid).not_to be_valid
      expect(invalid.errors[:estimated_price_cents]).to be_present
    end
  end

  describe "slug generation" do
    it "generates a slug from canonical_name on validation" do
      p = build(:product, canonical_name: "Catan: Expansão de Marinheiros", slug: nil)
      p.valid?
      expect(p.slug).to eq("catan-expansao-de-marinheiros")
    end

    it "does not overwrite an existing slug" do
      p = build(:product, canonical_name: "Catan", slug: "my-custom-slug")
      p.valid?
      expect(p.slug).to eq("my-custom-slug")
    end
  end

  describe "CATEGORIES constant" do
    it "includes expected values" do
      expect(Product::CATEGORIES).to contain_exactly("boardgame_base", "expansion")
    end
  end
end
