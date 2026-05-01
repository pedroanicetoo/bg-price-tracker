class TwilioGatewayService
  MAX_RETRIES      = 3
  RETRYABLE_CODES  = [429, 500, 503].freeze

  def initialize
    @client = Twilio::REST::Client.new(
      ENV.fetch("TWILIO_ACCOUNT_SID"),
      ENV.fetch("TWILIO_AUTH_TOKEN")
    )
    @from = ENV.fetch("TWILIO_WHATSAPP_FROM")
  end

  def send_message(to:, body:)
    attempts = 0

    begin
      attempts += 1
      message = @client.messages.create(from: @from, to: to, body: body)
      Rails.logger.info("[TwilioGatewayService] Sent #{message.sid} to #{masked(to)}")
      message
    rescue Twilio::REST::RestError => e
      if RETRYABLE_CODES.include?(e.status_code) && attempts < MAX_RETRIES
        wait = 2**attempts
        Rails.logger.warn("[TwilioGatewayService] Retryable error #{e.status_code}, retry #{attempts}/#{MAX_RETRIES} in #{wait}s")
        sleep(wait)
        retry
      end

      Rails.logger.error("[TwilioGatewayService] Failed to send to #{masked(to)}: #{e.message} (#{e.code})")
      raise TwilioGatewayService::Error, "Twilio error #{e.code}: #{e.message}"
    end
  end

  class Error < StandardError; end

  private

  def masked(number)
    number.to_s.gsub(/\d{4}\z/, "****")
  end
end
