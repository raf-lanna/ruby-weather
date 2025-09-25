require "test_helper"

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

    WeatherApi.any_instance.stub :fetch_current, ->(query:) {
      assert_equal "90001", query
      weather_payload
    } do
      get weather_forecast_path, params: { zip_code: "90001" }

      assert_response :success
      assert_select "h1", text: "Weather forecast"
      assert_select ".weather-card__location h2", text: /Los Angeles/
    end
  end

  test "GET /weather/forecast aceita busca por cidade" do
    weather_payload = {
      "location" => {
        "name" => "Los Angeles",
        "region" => "California",
        "country" => "United States of America"
      },
      "current" => { "temp_c" => 22.0 }
    }

    WeatherApi.any_instance.stub :fetch_current, ->(query:) {
      assert_equal "Los Angeles", query
      weather_payload
    } do
      get weather_forecast_path, params: { city: "Los Angeles" }

      assert_response :success
      assert_match "Showing forecast for city", response.body
    end
  end

  test "GET /weather/forecast avisa quando zip não existe" do
    error = WeatherApi::Error.new(message: "No matching location found.", code: 1006, http_status: 400)

    WeatherApi.any_instance.stub :fetch_current, ->(**) { raise error } do
      get weather_forecast_path, params: { zip_code: "99999" }

      assert_response :not_found
      assert_match "Não encontramos nenhuma localização com esses dados", response.body
    end
  end

  test "GET /weather/forecast mostra erro genérico quando API falha" do
    error = WeatherApi::Error.new(message: "Invalid API key", code: 1002, http_status: 400)

    WeatherApi.any_instance.stub :fetch_current, ->(**) { raise error } do
      get weather_forecast_path, params: { zip_code: "90001" }

      assert_response :bad_gateway
      assert_match "Não conseguimos obter a previsão agora", response.body
    end
  end

  test "GET /weather/forecast mostra erro genérico quando ocorre exceção inesperada" do
    WeatherApi.any_instance.stub :fetch_current, ->(**) { raise Timeout::Error } do
      get weather_forecast_path, params: { zip_code: "90001" }

      assert_response :bad_gateway
      assert_match "Não conseguimos obter a previsão agora", response.body
    end
  end

  test "GET /weather/forecast exige zip ou cidade" do
    get weather_forecast_path, params: { zip_code: "", city: "" }

    assert_response :unprocessable_entity
    assert_match "Enter a ZIP code or city", response.body
  end

  test "GET /weather/forecast rejeita zip com formato inválido" do
    get weather_forecast_path, params: { zip_code: "1234" }

    assert_response :unprocessable_entity
    assert_match "Enter a valid US ZIP code", response.body
  end
end
