require "test_helper"

module Forecasts
  class CacheKeyTest < ActiveSupport::TestCase
    test "builds key with zip scope when request uses a valid zip" do
      request = ForecastRequest.new(zip_code: "90001", days_from_now: 2)

      assert_equal "forecast_zip_90001_d2", CacheKey.for(request:)
    end

    test "builds key with city scope when request uses city" do
      request = ForecastRequest.new(city: "Los Angeles", days_from_now: 1)

      assert_equal "forecast_city_Los Angeles_d1", CacheKey.for(request:)
    end
  end
end
