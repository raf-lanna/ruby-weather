require "test_helper"

module Forecasts
  class FetchForecastTest < ActiveSupport::TestCase
    class FakeProvider
      attr_reader :calls

      def initialize(payload)
        @payload = payload
        @calls = []
      end

      def fetch_weather(query:, days: nil)
        @calls << { query:, days: }
        @payload
      end
    end

    test "loads forecast and marks cache miss on first call" do
      payload = { "location" => { "name" => "Los Angeles" }, "current" => { "temp_f" => 70 } }
      provider = FakeProvider.new(payload)
      cache = ActiveSupport::Cache::MemoryStore.new

      service = FetchForecast.new(weather_provider: provider, cache:)
      request = ForecastRequest.new(zip_code: "90001", days_from_now: 0)

      result = service.call(request:)

      assert_instance_of Forecast, result.forecast
      assert_equal false, result.cache_hit
      assert_equal [ { query: "90001", days: nil } ], provider.calls
    end

    test "returns cache hit and avoids second provider call" do
      payload = { "location" => { "name" => "Los Angeles" }, "current" => { "temp_f" => 70 } }
      provider = FakeProvider.new(payload)
      cache = ActiveSupport::Cache::MemoryStore.new

      service = FetchForecast.new(weather_provider: provider, cache:)
      request = ForecastRequest.new(zip_code: "90001", days_from_now: 0)

      first = service.call(request:)
      second = service.call(request:)

      assert_equal false, first.cache_hit
      assert_equal true, second.cache_hit
      assert_equal 1, provider.calls.length
    end

    test "requests forecast endpoint days when requesting future day" do
      payload = {
        "location" => { "name" => "Los Angeles" },
        "forecast" => {
          "forecastday" => [
            { "date" => "2026-04-01", "day" => {} },
            { "date" => "2026-04-02", "day" => {} },
            { "date" => "2026-04-03", "day" => { "avgtemp_f" => 72 } }
          ]
        }
      }
      provider = FakeProvider.new(payload)
      cache = ActiveSupport::Cache::MemoryStore.new

      service = FetchForecast.new(weather_provider: provider, cache:)
      request = ForecastRequest.new(zip_code: "90001", days_from_now: 2)

      service.call(request:)

      assert_equal [ { query: "90001", days: 3 } ], provider.calls
    end

    test "raises when days_from_now is invalid" do
      payload = { "location" => { "name" => "Los Angeles" }, "current" => { "temp_f" => 70 } }
      provider = FakeProvider.new(payload)
      cache = ActiveSupport::Cache::MemoryStore.new

      service = FetchForecast.new(weather_provider: provider, cache:)
      request = ForecastRequest.new(zip_code: "90001", days_from_now: "tomorrow")

      assert_raises(ArgumentError) do
        service.call(request:)
      end
      assert_empty provider.calls
    end
  end
end
