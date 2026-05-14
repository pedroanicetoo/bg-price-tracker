class NotificationPriceService
  def initialize(product:, user:)
    @product  = product
    @user     = user
    @crawler  = ComparaJogosCrawlerService.new
  end

  def call
    return unless query
    return if @product.price_cents == query.price_cents || @product.estimated_price_cents = query.price_cents
    return if @product.canonical_name != query.canonical_name

    notify_user
    ActiveRecord::Base.transaction do
      update_estimated_price
    end
  end

  private

  def notify_user
    if query.price_cents < @product.price_cents
      send_message(price_drop_message)
    else
      send_message(price_rise_message)
    end
  end

  def send_message(message_body)
    gateway.send_message(to: "whatsapp:#{@user.phone}", body: message_body)
  end

  def price_drop_message
    new_price = format("R$ %.2f", query.price_cents / 100.0)
    "📉 *#{query.canonical_name}* da sua lista está mais barato! Preço atual: #{new_price} ~ Atualizando preço estimado..."
  end

  def price_rise_message
    new_price = format("R$ %.2f", query.price_cents / 100.0)
    "📈 *#{query.canonical_name}* da sua lista subiu de preço. Preço atual: #{new_price}, ~ Atualizando preço estimado..."
  end

  def update_estimated_price
    @product.update_attributes(estimated_price_cents: query.price_cents)
  end

  def query
    @query ||= @crawler.call(@product.canonical_name, type: @product.category)
  end

  def gateway
    @gateway ||= TwilioGatewayService.new
  end
end
