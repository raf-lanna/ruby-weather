require "test_helper"
require "net/http"

class WeatherControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_api_key = ENV["WEATHER_API_KEY"]
    ENV["WEATHER_API_KEY"] = "test-key"
  end

  teardown do
    ENV["WEATHER_API_KEY"] = @original_api_key
  end

  test "GET /weather/forecast renders forecast when API returns data" do
    weather_payload = {
      "location" => {
        "name" => "Los Angeles",
        "region" => "California",
        "country" => "United States of America",
        "lat" => 34.05,
        "lon" => -118.24,
        "tz_id" => "America/Los_Angeles",
        "localtime" => "2025-09-24 15:32"
      },
      "current" => {
        "temp_c" => 25.6,
        "temp_f" => 78.1,
        "humidity" => 60,
        "wind_kph" => 15.1,
        "wind_dir" => "SW",
        "precip_in" => 0.0,
        "vis_miles" => 9.0,
        "uv" => 5.2,
        "last_updated" => "2025-09-24 15:30",
        "is_day" => 1,
        "condition" => {
          "text" => "Sunny",
          "icon" => "//cdn.weatherapi.com/weather/64x64/day/113.png",
          "code" => 1000
        }
      }
    }

    with_api_service(result: weather_payload) do
      get weather_forecast_path, params: { zip_code: "90001" }

      assert_response :success
      assert_select ".weather-card__location h2", text: /Los Angeles/
    end
  end

  test "GET /weather/forecast with days > 0 calls forecast" do
    weather_payload = {
      "location" => { "name" => "Los Angeles" },
      "forecast" => {
        "forecastday" => [
          {
            "date" => "2025-09-24",
            "day" => {
              "avgtemp_c" => 22.0,
              "avgtemp_f" => 71.6,
              "avghumidity" => 55,
              "maxwind_kph" => 10,
              "totalprecip_in" => 0.1,
              "avgvis_miles" => 8,
              "uv" => 4,
              "condition" => { "text" => "Partly cloudy", "icon" => "//icon.png", "code" => 1003 }
            }
          }
        ]
      }
    }

    with_api_service(result: weather_payload) do
      get weather_forecast_path, params: { zip_code: "90001", days: 1 }

      assert_response :success
      assert_select ".weather-card__location h2", text: /Los Angeles/
    end
  end

  test "GET /weather/forecast accepts search by city" do
    weather_payload = {
      "location" => {
        "name" => "Los Angeles",
        "region" => "California",
        "country" => "United States of America"
      },
      "current" => { "temp_c" => 22.0 }
    }

    with_api_service(result: weather_payload) do
      get weather_forecast_path, params: { city: "Los Angeles" }

      assert_response :success
      assert_select ".weather-card__location h2", text: /Los Angeles/
    end
  end

  test "GET /weather/forecast warns when ZIP does not exist" do
    error = WeatherApi::Error.new(message: "No matching location found.", code: 1006, http_status: 400)

    with_api_service(error: error) do
      get weather_forecast_path, params: { zip_code: "99999" }

      assert_response :not_found
      assert_match "We couldn't find a location with those details", response.body
    end
  end

  test "GET /weather/forecast shows generic error when API fails" do
    error = WeatherApi::Error.new(message: "Invalid API key", code: 1002, http_status: 400)

    with_api_service(error: error) do
      get weather_forecast_path, params: { zip_code: "90001" }

      assert_response :bad_gateway
      assert_match "We couldn't fetch the forecast right now", response.body
    end
  end

  test "GET /weather/forecast shows generic error when unexpected exception occurs" do
    with_api_service(error: Timeout::Error) do
      get weather_forecast_path, params: { zip_code: "90001" }

      assert_response :bad_gateway
      assert_match "We couldn't fetch the forecast right now", response.body
    end
  end

  test "GET /weather/forecast requires ZIP or city" do
    get weather_forecast_path, params: { zip_code: "", city: "" }

    assert_response :unprocessable_entity
    assert_match "Enter a ZIP code or city", response.body
  end

  test "GET /weather/forecast rejects invalid ZIP format" do
    get weather_forecast_path, params: { zip_code: "1234" }

    assert_response :unprocessable_entity
    assert_match "Enter a valid US ZIP code", response.body
  end
end
