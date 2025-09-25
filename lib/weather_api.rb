require "net/http"
require "uri"
require "json"

class WeatherApi
  BASE_URL = "https://api.weatherapi.com/v1".freeze
  FAILED_STATUS_WEATHER_API_MSG = "Weather API request failed with status".freeze
  API_KEY_NOT_SET_MSG = "WEATHER_API_KEY is not set".freeze
  ERROR_CODE_KEY = "code".freeze
  ERROR_MESSAGE_KEY = "message".freeze

  class Error < StandardError
    attr_reader :code, :http_status

    def initialize(message:, code: nil, http_status: nil)
      super(message)
      @code = code
      @http_status = http_status
    end
  end

  def fetch_current(query:)
    api_key = fetch_api_key

    uri = URI.parse("#{BASE_URL}/current.json")
    uri.query = URI.encode_www_form(key: api_key, q: query)

    response = Net::HTTP.get_response(uri)
    body = response.body

    unless response.is_a?(Net::HTTPSuccess)
      error_info = parse_error_payload(body)

      message = error_info[:message] || "#{FAILED_STATUS_WEATHER_API_MSG} #{response.code}"

      raise Error.new(
        message: message,
        code: error_info[:code],
        http_status: response.code.to_i
      )
    end

    JSON.parse(body)
  end

  def fetch_forecast(query:, days:)
    api_key = fetch_api_key

    uri = URI.parse("#{BASE_URL}/forecast.json")
    uri.query = URI.encode_www_form(key: api_key, q: query, days: days)

    response = Net::HTTP.get_response(uri)
    body = response.body

    unless response.is_a?(Net::HTTPSuccess)
      error_info = parse_error_payload(body)

      message = error_info[:message] || "#{FAILED_STATUS_WEATHER_API_MSG} #{response.code}"

      raise Error.new(
        message: message,
        code: error_info[:code],
        http_status: response.code.to_i
      )
    end

    JSON.parse(body)
  end

  private

  def fetch_api_key
    ENV.fetch("WEATHER_API_KEY") do
      raise KeyError, API_KEY_NOT_SET_MSG
    end
  end

  def parse_error_payload(body)
    json = JSON.parse(body)
    error = json.fetch("error", {})

    {
      code: error[ERROR_CODE_KEY],
      message: error[ERROR_MESSAGE_KEY]
    }
  rescue JSON::ParserError
    {}
  end
end
