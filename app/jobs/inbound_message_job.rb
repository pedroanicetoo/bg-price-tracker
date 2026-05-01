class InboundMessageJob < ApplicationJob
  queue_as :critical

  retry_on TwilioGatewayService::Error, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordInvalid

  def perform(twilio_params)
    from         = twilio_params["From"].to_s
    body         = twilio_params["Body"].to_s.strip
    profile_name = twilio_params["ProfileName"].to_s.strip
    msg_sid      = twilio_params["MessageSid"] || twilio_params["SmsMessageSid"]

    return if msg_sid.present? && already_processed?(msg_sid)

    phone  = normalize_phone(from)
    user   = User.find_by(phone: phone)

    result = route(user, phone, body, profile_name)
    result.messages.each { |message| gateway.send_message(to: from, body: message) }
    mark_processed!(msg_sid) if msg_sid.present?
  end

  private

  def route(user, phone, body, profile_name)
    case user&.consent_status
    when "accepted"
      OnBoardFlowService.new(user: user, text: body).call
    when "pending", "rejected"
      RegistrationService.new(phone: phone, text: body, profile_name: profile_name, user: user).call
    else
      RegistrationService.new(phone: phone, text: body, profile_name: profile_name).call
    end
  end

  def already_processed?(msg_sid)
    redis.exists?("processed_msg:#{msg_sid}")
  end

  def mark_processed!(msg_sid)
    redis.setex("processed_msg:#{msg_sid}", 24.hours.to_i, "1")
  end

  def normalize_phone(from)
    from.gsub(/\Awhatsapp:/, "")
  end

  def gateway
    @gateway ||= TwilioGatewayService.new
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  end
end
