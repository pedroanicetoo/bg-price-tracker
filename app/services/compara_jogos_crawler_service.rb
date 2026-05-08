class ComparaJogosCrawlerService
  API_URL = "https://api.comparajogos.com.br".freeze

  SEARCH_QUERY = <<~GQL.freeze
    query SearchProducts($name: String!, $type: product_type_enum!) {
      product_price(
        where: {
          new_count: { _gt: 0 }
          product: { name_unaccented: { _ilike: $name }, type: { _eq: $type } }
        }
        order_by: [{ min_price_new: asc }]
        limit: 20
      ) {
        id
        min_price_new
        new_count
        product {
          id
          name
          slug
          type
          publishers {
            publisher { name }
          }
        }
      }
    }
  GQL

  # Maps the Hasura product_type_enum to our internal category values.
  TYPE_TO_CATEGORY = {
    "game"      => "boardgame_base",
    "expansion" => "expansion"
  }.freeze

  # Reverse map: our category → Hasura product_type_enum value.
  CATEGORY_TO_TYPE = TYPE_TO_CATEGORY.invert.freeze

  class Error      < StandardError; end
  class HttpError  < Error; end
  class ParseError < Error; end

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
      canonical_name.present? && Product::CATEGORIES.include?(category)
    end
  end

  def initialize(connection: nil)
    @connection = connection || default_connection
  end

  def call(query, type: "boardgame_base")
    return nil if query.to_s.strip.empty?

    gql_type = CATEGORY_TO_TYPE.fetch(type.to_s, "game")
    entries  = graphql_search(query, gql_type)
    best     = select_best(entries)
    return nil unless best

    build_result(best)
  rescue HttpError, ParseError => e
    Rails.logger.error("[ComparaJogosCrawlerService] #{e.class}: #{e.message}")
    nil
  end

  private

  # Converts the user query into a Hasura _ilike pattern:
  # "terra mystica" → "%terra%mystica%"
  # This matches any product whose unaccented name contains all the words.
  def build_ilike(query)
    "%#{query.to_s.strip.split.join('%')}%"
  end

  def graphql_search(query, gql_type)
    response = @connection.post("/v1/graphql") do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["Origin"]       = "https://www.comparajogos.com.br"
      req.body = JSON.generate(query: SEARCH_QUERY, variables: { name: build_ilike(query), type: gql_type })
    end

    raise HttpError, "HTTP #{response.status} for query: #{query.truncate(80)}" unless response.status == 200

    parsed = JSON.parse(response.body)
    if parsed["errors"]
      raise ParseError, parsed["errors"].map { |e| e["message"] }.join("; ")
    end

    parsed.dig("data", "product_price") || []
  rescue JSON::ParserError => e
    raise ParseError, "JSON parse error: #{e.message}"
  end

  def select_best(entries)
    entries
      .select { |e| e["product"].present? && e["min_price_new"].to_f > 0 }
      .sort_by { |e| e["product"]["name"] }.first
  end

  def build_result(entry)
    product     = entry["product"]
    price_cents = (entry["min_price_new"].to_f * 100).round

    Result.new(
      canonical_name:           product["name"].to_s.strip,
      publisher:                extract_publisher(product["publishers"]),
      edition:                  extract_edition(product["name"]),
      language:                 "pt-BR",
      category:                 TYPE_TO_CATEGORY.fetch(product["type"].to_s, "boardgame_base"),
      price_cents:              price_cents,
      current_price_updated_at: Time.current,
      aliases:                  []
    ).then { |r| r.valid? ? r : nil }
  end


  def extract_publisher(publishers)
    return nil unless publishers.is_a?(Array) && publishers.any?

    names = publishers.filter_map { |row| row.dig("publisher", "name").presence }
    return nil if names.empty?

    names.find { |n| n.match?(/brasil|devir|galap[aá]gos|retro|papergames/i) } || names.first
  end


  def extract_edition(name)
    m = name.to_s.match(/\b(\d+[aªo°]?\s*edi[çc][aã]o|\d+(?:st|nd|rd|th)\s+edition)\b/i)
    m ? m[1] : nil
  end


  def default_connection
    Faraday.new(url: API_URL) do |f|
      f.options.timeout      = 15
      f.options.open_timeout = 5
      f.headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (compatible; BGPriceTracker/1.0)"
      f.request :retry, max: 2, interval: 2, backoff_factor: 2, retry_statuses: [500, 502, 503]
      f.adapter Faraday.default_adapter
    end
  end
end
