require "rails_helper"

RSpec.describe AppendingCollectionService do
  let(:user) { create(:user) }

  def stub_search(products)
    instance_double(ProductSearchService).tap do |s|
      allow(s).to receive(:call).and_return(Array(products))
    end
  end

  def build_service(query, search_result:)
    service = described_class.new(user: user, query: query)
    allow(ProductSearchService).to receive(:new).with(query).and_return(stub_search(search_result))
    service
  end

  describe "#call" do
    context "when no products are found" do
      it "returns a not-found message with done: true" do
        result = build_service("Jogo Desconhecido", search_result: []).call

        expect(result.done).to be true
        expect(result.messages.first).to match(/Não encontrei/)
      end
    end

    context "when a product is found" do
      let!(:saved_product) { create(:product, :catan) }

      context "and the product is already in the user's collection" do
        before { create(:collection_item, user: user, product: saved_product) }

        it "returns success without creating a duplicate" do
          result = build_service("Catan", search_result: [saved_product]).call

          expect(result.done).to be true
          expect(result.messages.first).to include("Catan")
          expect(CollectionItem.where(user: user, product: saved_product).count).to eq(1)
        end
      end

      context "and the product is not yet in the user's collection" do
        it "adds the product and returns a success message" do
          result = build_service("Catan", search_result: [saved_product]).call

          expect(result.done).to be true
          expect(result.messages.first).to include("Catan")
          expect(CollectionItem.exists?(user: user, product: saved_product)).to be true
        end
      end

      context "and the search returns an unsaved product (from external API)" do
        let(:unsaved_product) do
          Product.new(
            canonical_name: "Catan",
            publisher: "Devir",
            category: "boardgame_base",
            language: "pt-BR",
            aliases: [],
            slug: "catan"
          )
        end

        it "persists the product and adds it to the collection" do
          result = build_service("Catan", search_result: [unsaved_product]).call

          expect(result.done).to be true
          expect(Product.exists?(slug: "catan")).to be true
          expect(CollectionItem.exists?(user: user)).to be true
        end
      end

      context "and the user has reached the collection limit" do
        before do
          products = create_list(:product, CollectionItem::LIMIT)
          products.each { |p| create(:collection_item, user: user, product: p) }
        end

        it "returns an error message mentioning the limit" do
          result = build_service("Catan", search_result: [saved_product]).call

          expect(result.done).to be true
          expect(result.messages.first).to match(/limite/)
          expect(CollectionItem.where(user: user, product: saved_product).count).to eq(0)
        end
      end
    end
  end
end
