class MessageNotificationSchedulerJob < ApplicationJob

  def perform
    enqueue_user_products
  end

  private

  def enqueue_user_products
    User.active.each { |user| ProductNotificationJob.perform_later(user.id) }
  end
end
