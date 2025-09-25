class WeatherController < ApplicationController
  def index
    @zip_code = params[:zip_code]
  end

  def forecast
    @zip_code = params[:zip_code].to_s.strip

    if @zip_code.blank?
      flash.now[:alert] = "Enter a ZIP code to check the forecast."
      render :index, status: :unprocessable_entity
      return
    end

    unless valid_zip_code?(@zip_code)
      flash.now[:alert] = "Enter a valid US ZIP code (12345 or 12345-6789)."
      render :index, status: :unprocessable_entity
      return
    end

    api_service = ApiService.new

    begin
      response = api_service.fetch_weather(zip_code: @zip_code)
      @forecast = Forecast.from_api_response(response)
    rescue WeatherApi::Error => e
      Rails.logger.warn("Weather API error (code=#{e.code}, status=#{e.http_status}): #{e.message}")

      if e.code.to_i == 1006
        flash.now[:alert] = "Não encontramos nenhuma localização com esse ZIP code. Confira se o código existe e tente novamente."
        render :index, status: :not_found
      else
        flash.now[:alert] = "Não conseguimos obter a previsão agora. Tente novamente em instantes."
        render :index, status: :bad_gateway
      end
    rescue StandardError => e
      Rails.logger.error("Weather API unexpected error: #{e.message}")
      flash.now[:alert] = "Não conseguimos obter a previsão agora. Tente novamente em instantes."
      render :index, status: :bad_gateway
    end
  end

  private

  def valid_zip_code?(zip_code)
    digits = zip_code.delete("^0-9")
    (digits.length == 5 || digits.length == 9) &&
      (zip_code.match?(/\A\d{5}\z/) || zip_code.match?(/\A\d{5}-\d{4}\z/))
  end
end
