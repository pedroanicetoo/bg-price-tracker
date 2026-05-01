module Webhooks
  class WhatsappController < ApplicationController
    before_action :validate_twilio_signature!, unless: :skip_signature_validation?

    def inbound
      InboundMessageJob.perform_later(safe_params)
      head :ok
    end

    private

    def validate_twilio_signature!
      auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")
      validator  = Twilio::Security::RequestValidator.new(auth_token)
      signature  = request.headers["X-Twilio-Signature"].to_s

      unless validator.validate(request.original_url, request.request_parameters, signature)
        Rails.logger.warn("[Webhooks::WhatsappController] Invalid Twilio signature — IP: #{request.remote_ip}")
        head :forbidden
      end
    end


    def safe_params
      params.permit(
        :From, :To, :Body, :MessageSid, :SmsMessageSid,
        :AccountSid, :ProfileName, :WaId, :NumMedia
      ).to_h
    end

    def skip_signature_validation?
      Rails.env.development? || Rails.env.test?
    end
  end
end
