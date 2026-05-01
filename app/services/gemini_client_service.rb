class GeminiClientService
  BASE_URL = "https://generativelanguage.googleapis.com".freeze
  MODEL    = "gemini-2.5-flash-lite".freeze

  class Error           < StandardError; end
  class ApiError        < Error; end
  class ParseError      < Error; end
  class QuotaError      < ApiError; end

  Response = Struct.new(:text, keyword_init: true)

  def initialize(api_key: ENV.fetch("GEMINI_API_KEY"), connection: nil)
    @api_key    = api_key
    @connection = connection || default_connection
  end

  def call(prompt:, temperature: 0.1)
    body = build_body(prompt, temperature)
    http_response = @connection.post(endpoint_path, body.to_json)

    handle_response(http_response)
  end

  private

  def endpoint_path
    "/v1beta/models/#{MODEL}:generateContent?key=#{@api_key}"
  end

  def build_body(prompt, temperature)
    {
      contents: [
        { role: "user", parts: [{ text: prompt }] }
      ],
      generationConfig: {
        temperature:      temperature,
        maxOutputTokens:  1024,
        responseMimeType: "application/json"
      }
    }
  end

  def handle_response(http_response)
    case http_response.status
    when 200
      parse_text(http_response.body)
    when 429
      raise QuotaError, "Gemini quota exceeded (429)"
    else
      raise ApiError, "Gemini API error #{http_response.status}: #{http_response.body}"
    end
  end

  def parse_text(body)
    data = body.is_a?(Hash) ? body : JSON.parse(body)
    text = data.dig("candidates", 0, "content", "parts", 0, "text")
    raise ParseError, "Unexpected Gemini response shape: #{data.inspect}" unless text

    Response.new(text: text.strip)
  rescue JSON::ParserError => e
    raise ParseError, "Failed to parse Gemini response: #{e.message}"
  end

  def default_connection
    Faraday.new(url: BASE_URL) do |f|
      f.options.timeout      = 30
      f.options.open_timeout = 5
      f.request  :json
      f.response :json
      f.request :retry, max: 3, interval: 5, backoff_factor: 2, retry_statuses: [429, 500, 502, 503]
      f.adapter  Faraday.default_adapter
    end
  end
end
