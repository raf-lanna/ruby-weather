require "net/http"
require "uri"
require "json"

class WeatherApi
  BASE_URL = "https://api.weatherapi.com/v1".freeze

  class Error < StandardError
    attr_reader :code, :http_status

    def initialize(message:, code: nil, http_status: nil)
      super(message)
      @code = code
      @http_status = http_status
    end
  end

  def fetch_current(zip_code:)
    api_key = ENV.fetch("WEATHER_API_KEY") do
      raise "WEATHER_API_KEY is not set"
    end

    uri = URI.parse("#{BASE_URL}/current.json")
    uri.query = URI.encode_www_form(key: api_key, q: zip_code)

    response = Net::HTTP.get_response(uri)
    body = response.body

    unless response.is_a?(Net::HTTPSuccess)
      error_info = parse_error_payload(body)

      message = error_info[:message] || "Weather API request failed with status #{response.code}"

      raise Error.new(
        message: message,
        code: error_info[:code],
        http_status: response.code.to_i
      )
    end

    JSON.parse(body)
  end

  private

  def parse_error_payload(body)
    json = JSON.parse(body)
    error = json.fetch("error", {})

    {
      code: error["code"],
      message: error["message"]
    }
  rescue JSON::ParserError
    {}
  end
end

