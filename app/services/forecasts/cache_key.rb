module Forecasts
  class CacheKey
    def self.for(request:)
      scope = request.using_zip? ? "zip" : "city"
      "forecast_#{scope}_#{request.location}_d#{request.days_from_now}"
    end
  end
end
