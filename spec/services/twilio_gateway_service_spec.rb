require "rails_helper"

RSpec.describe TwilioGatewayService do
  let(:messages_api) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList) }
  let(:client) { instance_double(Twilio::REST::Client, messages: messages_api) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("TWILIO_ACCOUNT_SID").and_return("AC123")
    allow(ENV).to receive(:fetch).with("TWILIO_AUTH_TOKEN").and_return("token")
    allow(ENV).to receive(:fetch).with("TWILIO_WHATSAPP_FROM").and_return("whatsapp:+14155238886")
    allow(Twilio::REST::Client).to receive(:new).and_return(client)
  end

  def rest_error(status:, code:, message:)
    body = { code: code, message: message }.to_json
    response = Twilio::Response.new(status, body, headers: { "content-type" => "application/json" })
    Twilio::REST::RestError.new(message, response)
  end

  describe "#send_message" do
    it "sends message and returns Twilio message object" do
      twilio_message = instance_double(Twilio::REST::Api::V2010::AccountContext::MessageInstance, sid: "SM123")
      expect(messages_api).to receive(:create)
        .with(from: "whatsapp:+14155238886", to: "whatsapp:+5511999999999", body: "oi")
        .and_return(twilio_message)

      result = described_class.new.send_message(to: "whatsapp:+5511999999999", body: "oi")
      expect(result).to eq(twilio_message)
    end

    it "retries transient errors and succeeds" do
      twilio_message = instance_double(Twilio::REST::Api::V2010::AccountContext::MessageInstance, sid: "SM124")
      transient = rest_error(status: 429, code: 20429, message: "rate limit")

      service = described_class.new
      allow(service).to receive(:sleep)
      expect(messages_api).to receive(:create).and_raise(transient).ordered
      expect(messages_api).to receive(:create).and_return(twilio_message).ordered

      result = service.send_message(to: "whatsapp:+5511999999999", body: "oi")
      expect(result).to eq(twilio_message)
    end

    it "raises service error for non-retryable errors" do
      non_retryable = rest_error(status: 400, code: 21211, message: "invalid to")
      allow(messages_api).to receive(:create).and_raise(non_retryable)

      expect {
        described_class.new.send_message(to: "whatsapp:+5511999999999", body: "oi")
      }.to raise_error(TwilioGatewayService::Error, /Twilio error 21211/)
    end
  end
end
