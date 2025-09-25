class ApiService
  def initialize(weather_client: WeatherApi.new)
    @weather_client = weather_client
  end

  def fetch_weather(query:, days: 0)
    @weather_client.fetch_forecast(query: query, days: days)
  end
end
