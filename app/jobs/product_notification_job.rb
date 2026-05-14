class ProductNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    enqueue_price_check_jobs(user)
  end

  private

  def enqueue_price_check_jobs(user)
    user.collected_products.each { |product| PriceCheckJob.perform_later(product.id, user.id) }
  end
end
