class Product < ApplicationRecord
  CATEGORIES = %w[boardgame_base expansion].freeze
  monetize :price_cents, as: :price, allow_nil: true
  monetize :estimated_price_cents, as: :estimated_price, allow_nil: true

  has_many :collection_items
  has_many :collectors, through: :collection_items, source: :user

  validates :canonical_name, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :slug, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :current_price_updated_at, presence: true, if: -> { price_cents.to_i > 0 }
  validates :estimated_price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :by_under_price, -> (price_cents) {
    where(products: { price_cents: ..price_cents })
  }

  before_validation :generate_slug, if: -> { slug.blank? && canonical_name.present? }

  private

  def generate_slug
    self.slug = canonical_name
      .to_s
      .unicode_normalize(:nfd)
      .gsub(/\p{Mn}/, "")
      .downcase
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/(^-|-$)/, "")
  end
end
