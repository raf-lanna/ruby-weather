class WeatherController < ApplicationController
  def index
    @zip_code = params[:zip_code]
    @city = params[:city]
    @days = params[:days].present? ? params[:days].to_i.clamp(0, 5) : 0
  end

  def forecast
    @zip_code = params[:zip_code].to_s.strip
    @city = params[:city].to_s.strip

    @days = params[:days].present? ? params[:days].to_i.clamp(0, 5) : 0

    if @zip_code.blank? && @city.blank?
      flash.now[:alert] = "Enter a ZIP code or city to check the forecast."
      render :index, status: :unprocessable_entity
      return
    end

    location = detect_location
    unless location
      render :index, status: :unprocessable_entity
      return
    end

    api_service = ApiService.new
    cache_key = cache_key_for(location)
    api_days = @days.positive? ? (@days + 1).clamp(1, 6) : nil

    begin
      cache_hit = true
      @forecast = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        cache_hit = false
        response = api_service.fetch_weather(query: location, days: api_days)
        Forecast.from_api_response(response, day_offset: @days)
      end
      flash.now[:notice] = "This forecast came from cache and may be up to 30 minutes old." if cache_hit
    rescue WeatherApi::Error => e
      Rails.logger.warn("Weather API error (code=#{e.code}, status=#{e.http_status}): #{e.message}")

      if e.code.to_i == 1006
        flash.now[:alert] = "We couldn't find a location with those details. Please check the ZIP code or city name."
        render :index, status: :not_found
      else
        flash.now[:alert] = "We couldn't fetch the forecast right now. Please try again shortly."
        render :index, status: :bad_gateway
      end
      return
    rescue StandardError => e
      Rails.logger.error("Weather API unexpected error: #{e.message}")
      flash.now[:alert] = "We couldn't fetch the forecast right now. Please try again shortly."
      render :index, status: :bad_gateway
      return
    end
  end

  private

  def cache_key_for(location)
    scope = @zip_code.present? ? "zip" : "city"
    "forecast_#{scope}_#{location}_d#{@days}"
  end

  def detect_location
    if @zip_code.present?
      return @zip_code if valid_zip_code?(@zip_code)

      flash.now[:alert] = "Enter a valid US ZIP code (12345 or 12345-6789)."
      return nil
    end

    if @city.present?
      return @city
    end

    nil
  end

  def valid_zip_code?(zip_code)
    digits = zip_code.delete("^0-9")
    (digits.length == 5 || digits.length == 9) &&
      (zip_code.match?(/\A\d{5}\z/) || zip_code.match?(/\A\d{5}-\d{4}\z/))
  end
end
