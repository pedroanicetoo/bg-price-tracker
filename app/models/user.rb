class User < ApplicationRecord
  has_many :collection_items, dependent: :destroy
  has_many :collected_products, through: :collection_items, source: :product

  CONSENT_STATUSES = %w[pending accepted rejected revoked].freeze

  PHONE_FORMAT = /\A\+[1-9]\d{6,14}\z/.freeze

  validates :consent_status, inclusion: { in: CONSENT_STATUSES }
  validates :phone, uniqueness: { allow_nil: true }
  validates :phone, format: { with: PHONE_FORMAT, message: "precisa estar no formato E.164 (+XXXXXXXXXX)" },
                    allow_nil: true

  scope :accepted, -> { where(consent_status: "accepted") }
  scope :active,   -> { accepted.where(anonymized_at: nil) }

  def accepted?
    consent_status == "accepted"
  end

  def anonymized?
    anonymized_at.present?
  end

  def anonymize!
    transaction do
      update_columns(
        phone:          "ANONIMIZADO_#{Digest::SHA256.hexdigest(phone.to_s)}",
        consent_status: "revoked",
        anonymized_at:  Time.current
      )
    end
  end
end
