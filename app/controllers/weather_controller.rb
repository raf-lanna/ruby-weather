class WeatherController < ApplicationController
  def index
    @zip_code = params[:zip_code]
    @city = params[:city]
  end

  def forecast
    @zip_code = params[:zip_code].to_s.strip
    @city = params[:city].to_s.strip

    if @zip_code.blank? && @city.blank?
      flash.now[:alert] = "Enter a ZIP code or city to check the forecast."
      render :index, status: :unprocessable_entity
      return
    end

    query = define_query_type
    unless query
      render :index, status: :unprocessable_entity
      return
    end

    api_service = ApiService.new
    cache_key = cache_key_for(query)

    begin
      cache_hit = true
      @forecast = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        cache_hit = false
        response = api_service.fetch_weather(query: query)
        Forecast.from_api_response(response)
      end
      flash.now[:notice] = "Esta previsão veio do cache e pode estar desatualizada (até 30 minutos)." if cache_hit
    rescue WeatherApi::Error => e
      Rails.logger.warn("Weather API error (code=#{e.code}, status=#{e.http_status}): #{e.message}")

      if e.code.to_i == 1006
        flash.now[:alert] = "Não encontramos nenhuma localização com esses dados. Confira se o ZIP code ou nome da cidade estão corretos."
        render :index, status: :not_found
      else
        flash.now[:alert] = "Não conseguimos obter a previsão agora. Tente novamente em instantes."
        render :index, status: :bad_gateway
      end
      return
    rescue StandardError => e
      Rails.logger.error("Weather API unexpected error: #{e.message}")
      flash.now[:alert] = "Não conseguimos obter a previsão agora. Tente novamente em instantes."
      render :index, status: :bad_gateway
      return
    end
  end

  private

  def cache_key_for(query)
    type = @zip_code.present? ? "zip" : "city"
    "forecast_#{type}_#{query}"
  end

  def define_query_type
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
