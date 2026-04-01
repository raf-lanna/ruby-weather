module Forecasts
  class FetchForecast
    Result = Struct.new(:forecast, :cache_hit, keyword_init: true)

    CACHE_TTL = 30.minutes

    def initialize(
      weather_provider: ExternalApiService.new,
      cache: Rails.cache,
      forecast_factory: ->(response, day_offset) { Forecast.from_api_response(response, day_offset:) }
    )
      @weather_provider = weather_provider
      @cache = cache
      @forecast_factory = forecast_factory
    end

    def call(request:)
      cache_hit = true
      forecast = @cache.fetch(CacheKey.for(request:), expires_in: CACHE_TTL) do
        cache_hit = false
        response = @weather_provider.fetch_weather(query: request.location, days: api_days_for(request.days_from_now))
        @forecast_factory.call(response, request.days_from_now)
      end

      Result.new(forecast:, cache_hit:)
    end

    private

    def api_days_for(days_from_now)
      numeric_days = Integer(days_from_now, exception: false)
      unless numeric_days && numeric_days.between?(0, 5)
        raise ArgumentError, "days_from_now must be an integer between 0 and 5"
      end
      return nil if numeric_days.zero?

      (numeric_days + 1).clamp(1, 6)
    end
  end
end
