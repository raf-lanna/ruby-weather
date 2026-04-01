require "test_helper"
require "net/http"

class WeatherApiTest < ActiveSupport::TestCase
  class FakeHttpClient
    attr_accessor :response
    attr_reader :last_start_args, :last_start_kwargs

    def start(*args, **kwargs)
      @last_start_args = args
      @last_start_kwargs = kwargs
      yield self
    end

    def get(_request_uri)
      @response
    end
  end

  def setup
    @original_api_key = ENV["WEATHER_API_KEY"]
    ENV["WEATHER_API_KEY"] = "test-key"
    @http_client = FakeHttpClient.new
    @api = WeatherApi.new(http_client: @http_client)
  end

  def teardown
    ENV["WEATHER_API_KEY"] = @original_api_key
  end

  test "fetch_current returns parsed data when response succeeds" do
    body = {
      "location" => { "name" => "Los Angeles" },
      "current" => { "temp_c" => 22.1 }
    }.to_json

    response = build_response(Net::HTTPSuccess, "200", body)
    @http_client.response = response
    result = @api.fetch_current(query: "90001")

    assert_equal "Los Angeles", result.dig("location", "name")
    assert_in_delta 22.1, result.dig("current", "temp_c")
  end

  test "fetch_current uses explicit HTTP timeouts" do
    body = {
      "location" => { "name" => "Los Angeles" },
      "current" => { "temp_c" => 22.1 }
    }.to_json
    response = build_response(Net::HTTPSuccess, "200", body)
    @http_client.response = response
    @api.fetch_current(query: "90001")

    assert_equal true, @http_client.last_start_kwargs[:use_ssl]
    assert_equal WeatherApi::HTTP_OPEN_TIMEOUT_SECONDS, @http_client.last_start_kwargs[:open_timeout]
    assert_equal WeatherApi::HTTP_READ_TIMEOUT_SECONDS, @http_client.last_start_kwargs[:read_timeout]
  end

  test "fetch_current raises WeatherApi::Error when location is not found" do
    error_body = {
      "error" => {
        "code" => 1006,
        "message" => "No matching location found."
      }
    }.to_json

    response = build_response(Net::HTTPClientError, "400", error_body)
    @http_client.response = response

    error = assert_raises(WeatherApi::Error) do
      @api.fetch_current(query: "99999")
    end

    assert_equal 1006, error.code
    assert_equal 400, error.http_status
    assert_equal "No matching location found.", error.message
  end

  test "fetch_current raises WeatherApi::Error with default message when body is not json" do
    response = build_response(Net::HTTPServerError, "500", "<!DOCTYPE html>")
    @http_client.response = response

    error = assert_raises(WeatherApi::Error) do
      @api.fetch_current(query: "90001")
    end

    assert_nil error.code
    assert_equal 500, error.http_status
    assert_equal "Weather API request failed with status 500", error.message
  end

  test "raises if WEATHER_API_KEY is not set" do
    ENV.delete("WEATHER_API_KEY")

    assert_raises(KeyError) do
      WeatherApi.new.fetch_current(query: "90001")
    end
  ensure
    ENV["WEATHER_API_KEY"] = @original_api_key || "test-key"
  end

  private

  def build_response(klass, status, body)
    response = klass.new("1.1", status, "Response")
    response.instance_variable_set(:@read, true)
    response.instance_variable_set(:@body, body)
    response
  end
end
