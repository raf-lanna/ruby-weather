require "test_helper"
require "net/http"

class WeatherApiTest < ActiveSupport::TestCase
  def setup
    @original_api_key = ENV["WEATHER_API_KEY"]
    ENV["WEATHER_API_KEY"] = "test-key"
    @api = WeatherApi.new
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

    with_http_response(response) do
      result = @api.fetch_current(query: "90001")

      assert_equal "Los Angeles", result.dig("location", "name")
      assert_in_delta 22.1, result.dig("current", "temp_c")
    end
  end

  test "fetch_current raises WeatherApi::Error when location is not found" do
    error_body = {
      "error" => {
        "code" => 1006,
        "message" => "No matching location found."
      }
    }.to_json

    response = build_response(Net::HTTPClientError, "400", error_body)

    with_http_response(response) do
      error = assert_raises(WeatherApi::Error) do
        @api.fetch_current(query: "99999")
      end

      assert_equal 1006, error.code
      assert_equal 400, error.http_status
      assert_equal "No matching location found.", error.message
    end
  end

  test "fetch_current raises WeatherApi::Error with default message when body is not json" do
    response = build_response(Net::HTTPServerError, "500", "<!DOCTYPE html>")

    with_http_response(response) do
      error = assert_raises(WeatherApi::Error) do
        @api.fetch_current(query: "90001")
      end

      assert_nil error.code
      assert_equal 500, error.http_status
      assert_equal "Weather API request failed with status 500", error.message
    end
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
