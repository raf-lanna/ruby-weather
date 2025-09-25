class ApiService
  def initialize(weather_client: WeatherApi.new)
    @weather_client = weather_client
  end

  def fetch_weather(query:)
    @weather_client.fetch_current(query: query)
  end
end
