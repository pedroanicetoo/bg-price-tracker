class CollectionItem < ApplicationRecord
  LIMIT = 50

  belongs_to :user
  belongs_to :product, dependent: :destroy

  validates :user_id,    presence: true
  validates :product_id, presence: true
  validates :product_id, uniqueness: { scope: :user_id, message: "já está na sua coleção" }
  validate  :collection_limit_not_exceeded, on: :create



  before_validation :set_added_at, on: :create

  private

  def set_added_at
    self.added_at ||= Time.current
  end

  def collection_limit_not_exceeded
    return unless user_id

    count = CollectionItem.where(user_id: user_id).count
    if count >= LIMIT
      errors.add(:base, "limite de #{LIMIT} itens na coleção atingido")
    end
  end
end
