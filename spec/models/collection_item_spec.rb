require "rails_helper"

RSpec.describe CollectionItem, type: :model do
  subject(:item) { build(:collection_item, user: user, product: product) }

  let(:user)    { create(:user) }
  let(:product) { create(:product, :catan) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:product) }
  end

  describe "validations" do
    it "is valid with user and product" do
      expect(item).to be_valid
    end

    it "rejects duplicate user+product pairs" do
      create(:collection_item, user: user, product: product)
      duplicate = build(:collection_item, user: user, product: product)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to be_present
    end

    it "allows the same product in different users' collections" do
      other_user = create(:user, phone: "+5562800000001")
      create(:collection_item, user: user, product: product)
      item2 = build(:collection_item, user: other_user, product: product)
      expect(item2).to be_valid
    end
  end

  describe "collection limit" do
    it "rejects a 51st item for the same user" do
      products = create_list(:product, CollectionItem::LIMIT)
      products.each { |p| create(:collection_item, user: user, product: p) }

      overflow_product = create(:product)
      overflow_item    = build(:collection_item, user: user, product: overflow_product)

      expect(overflow_item).not_to be_valid
      expect(overflow_item.errors[:base]).to include(/limite de 50 itens/)
    end

    it "allows exactly 50 items" do
      products = create_list(:product, CollectionItem::LIMIT - 1)
      products.each { |p| create(:collection_item, user: user, product: p) }

      last_item = build(:collection_item, user: user, product: product)
      expect(last_item).to be_valid
    end
  end

  describe "added_at" do
    it "is set automatically before creation" do
      item.added_at = nil
      item.save!
      expect(item.reload.added_at).to be_present
    end
  end
end
