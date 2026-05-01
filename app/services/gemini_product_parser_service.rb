class GeminiProductParserService
  CATEGORIES = Product::CATEGORIES
  PROMPT_TEMPLATE_PATH = Rails.root.join("app/prompt_templates/search-product-prompt.md").freeze

  Result = Struct.new(
    :canonical_name,
    :publisher,
    :edition,
    :language,
    :category,
    :aliases,
    :price_cents,
    :current_price_updated_at,
    keyword_init: true

  ) do
    def valid?
      canonical_name.present? && CATEGORIES.include?(category)
    end
  end

  def initialize(client: GeminiClientService.new)
    @client = client
  end

  def call(query)
    return nil if query.to_s.strip.empty?

    response = @client.call(prompt: build_prompt(query))
    parse(response.text)
  rescue GeminiClientService::Error => e
    Rails.logger.error("[GeminiProductParserService] API error: #{e.message}")
    nil
  end

  private

  def parse(text)
    clean = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
    data  = JSON.parse(clean)

    return nil if data["error"] == "not_found"

    Result.new(
      canonical_name:           data["canonical_name"].to_s.strip,
      publisher:                data["publisher"],
      edition:                  data["edition"],
      language:                 data["language"].presence || "pt-BR",
      category:                 normalize_category(data["category"]),
      price_cents:              data["price_cents"] || 0,
      current_price_updated_at: Time.current,
      aliases:                  Array(data["aliases"]).map(&:to_s).reject(&:empty?)
    ).then { |r| r.valid? ? r : nil }
  rescue JSON::ParserError => e
    Rails.logger.warn("[GeminiProductParserService] Failed to parse JSON: #{e.message} | raw: #{text.truncate(200)}")
    nil
  end

  def normalize_category(value)
    str = value.to_s.strip.downcase
    CATEGORIES.include?(str) ? str : "boardgame_base"
  end

  def build_prompt(query)
    format(prompt_template, query: query.to_s.gsub('"', "'"))
  end

  def prompt_template
    File.read(PROMPT_TEMPLATE_PATH)
  end

end
