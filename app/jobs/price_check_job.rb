class PriceCheckJob < ApplicationJob
  queue_as :critical

  def perform(product_id, user_id)
    @user = User.find_by(id: user_id)
    @product = @user.collected_products.find_by(id: product_id)
    process_price_check
  end

  private

  def process_price_check
    NotificationPriceService.new(product: @product, user: @user).call
  end
end
