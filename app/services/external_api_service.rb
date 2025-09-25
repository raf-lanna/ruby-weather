class ExternalApiService
  def initialize(weather_client: WeatherApi.new)
    @weather_client = weather_client
  end

  def fetch_weather(query:, days: nil)
    if days.present? && days.positive?
      @weather_client.fetch_forecast(query: query, days: days)
    else
      @weather_client.fetch_current(query: query)
    end
  end
end
