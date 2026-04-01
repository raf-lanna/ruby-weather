require "net/http"
require "uri"
require "json"

class WeatherApi
  BASE_URL = "https://api.weatherapi.com/v1".freeze
  FAILED_STATUS_WEATHER_API_MSG = "Weather API request failed with status".freeze
  API_KEY_NOT_SET_MSG = "WEATHER_API_KEY is not set".freeze
  ERROR_CODE_KEY = "code".freeze
  ERROR_MESSAGE_KEY = "message".freeze
  HTTP_OPEN_TIMEOUT_SECONDS = 5
  HTTP_READ_TIMEOUT_SECONDS = 8

  class Error < StandardError
    attr_reader :code, :http_status

    def initialize(message:, code: nil, http_status: nil)
      super(message)
      @code = code
      @http_status = http_status
    end
  end

  def initialize(http_client: Net::HTTP)
    @http_client = http_client
  end

  def fetch_current(query:)
    request_json(endpoint: "current", query:, days: nil)
  end

  def fetch_forecast(query:, days:)
    request_json(endpoint: "forecast", query:, days:)
  end

  private

  def request_json(endpoint:, query:, days:)
    api_key = fetch_api_key
    uri = URI.parse("#{BASE_URL}/#{endpoint}.json")
    params = { key: api_key, q: query }
    params[:days] = days if days.present?
    uri.query = URI.encode_www_form(params)

    response = @http_client.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: HTTP_OPEN_TIMEOUT_SECONDS,
      read_timeout: HTTP_READ_TIMEOUT_SECONDS
    ) do |http|
      http.get(uri.request_uri)
    end

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
