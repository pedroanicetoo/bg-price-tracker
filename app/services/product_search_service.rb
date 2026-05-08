class ProductSearchService
  MAX_RESULTS = 5

  def initialize(query, parser: ComparaJogosCrawlerService.new)
    @query  = query.to_s.strip
    @parser = parser
  end

  def call
    return [] if @query.empty?

    parsed = @parser.call(@query)
    return [] unless parsed

    db_matches = find_in_db([parsed.canonical_name] + parsed.aliases)
    return db_matches unless db_matches.empty?

    [build_product(parsed)]
  end

  private

  def find_in_db(names)
    slugs = names.map { |n| slugify(n) }.uniq
    Product.where(slug: slugs).limit(MAX_RESULTS).to_a
  end

  def build_product(parsed)
    Product.new(
      canonical_name:           parsed.canonical_name,
      publisher:                parsed.publisher,
      edition:                  parsed.edition,
      language:                 parsed.language,
      category:                 parsed.category,
      price_cents:              parsed.price_cents,
      current_price_updated_at: parsed.current_price_updated_at,
      aliases:                  Array(parsed.aliases),
      slug:                     slugify(parsed.canonical_name)
    )
  end

  def slugify(name)
    name.to_s
        .unicode_normalize(:nfd)
        .gsub(/\p{Mn}/, "")
        .downcase
        .gsub(/[^\w\s]/, " ")
        .gsub(/\s+/, "-")
        .strip
  end
end
