class AppendingCollectionService
  # encoding: utf-8
  Result = Struct.new(:messages, :done, keyword_init: true)

  def initialize(user:, query: query, session_manager: nil)
    @user = user
    @query = query
  end

  def call
    if results.empty?
      done(product_not_found_msg)
    else
      appending_to_collection(results.first)
    end
  end

  private

  def appending_to_collection(product)
    @product = product

    return done(success_message(record)) if CollectionItem.exists?(user: @user, product: record)

    item = CollectionItem.new(user: @user, product: record)

    if item.save
      done(success_message(record))
    else
      done("Não foi possível adicionar o item: #{item.errors.full_messages.first}")
    end
  rescue ActiveRecord::RecordInvalid => e
    done("Não foi possível cadastrar o produto: #{e.message}")
  end

  def success_message(product)
    edition = product.edition.present? ? " (#{product.edition})" : ""
    <<~MSG.strip
      ✅ *#{product.canonical_name}*#{edition} adicionado à sua coleção!

      📦 #{I18n.t('active_record.models.product.attributes.category')}: #{product.category.presence || "não informada"}
      🏭 #{I18n.t('active_record.models.product.attributes.publisher')}: #{product.publisher.presence || "não informada"}
      🏷️ #{I18n.t('active_record.models.product.attributes.price')}: #{product.price_cents.present? ? "#{product.price.format}" : "não informado"}

      Você receberá alertas quando o preço cair. 🔔
    MSG
  end

  def record
    @record ||= Product.find_or_create_by!(slug: @product.slug) do |p|
      p.canonical_name           = @product.canonical_name
      p.publisher                = @product.publisher
      p.edition                  = @product.edition
      p.language                 = @product.language
      p.category                 = @product.category
      p.price_cents              = @product.price_cents
      p.current_price_updated_at = @product.current_price_updated_at
      p.aliases                  = @product.aliases
    end
  end

  def results
    @results ||= ProductSearchService.new(@query).call
  end

  def product_not_found_msg
    I18n.t('services.product_not_found', product: @query)
  end

  def done(message)
    Result.new(messages: [message], done: true)
  end
end
