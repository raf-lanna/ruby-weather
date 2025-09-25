class ApiService
  def initialize(weather_client: WeatherApi.new)
    @weather_client = weather_client
  end

  def fetch_weather(zip_code:)
    @weather_client.fetch_current(zip_code: zip_code)
  end
end
