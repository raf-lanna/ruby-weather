class WeatherController < ApplicationController
  before_action :build_forecast_request

  def index; end

  def forecast
    unless @forecast_request.valid?
      flash.now[:alert] = @forecast_request.errors.full_messages.first
      render :index, status: :unprocessable_entity
      return
    end

    external_api_service = ExternalApiService.new
    cache_key = cache_key_for(@forecast_request.location)
    api_days = @forecast_request.days_from_now.positive? ? (@forecast_request.days_from_now + 1).clamp(1, 6) : nil

    begin
      cache_hit = true
      @forecast = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        cache_hit = false
        response = external_api_service.fetch_weather(query: @forecast_request.location, days: api_days)
        Forecast.from_api_response(response, day_offset: @forecast_request.days_from_now)
      end
      flash.now[:notice] = ForecastRequest::CACHE_MSG if cache_hit
    rescue WeatherApi::Error => e
      Rails.logger.warn("Weather API error (code=#{e.code}, status=#{e.http_status}): #{e.message}")

      if e.code.to_i == ForecastRequest::NOT_FOUND_CODE
        flash.now[:alert] = ForecastRequest::RESPONSE_CODE_1006
        render :index, status: :not_found
      else
        flash.now[:alert] = ForecastRequest::TRY_AGAIN_MSG
        render :index, status: :bad_gateway
      end
    rescue StandardError => e
      Rails.logger.error("Weather API unexpected error: #{e.message}")
      flash.now[:alert] = ForecastRequest::TRY_AGAIN_MSG
      render :index, status: :bad_gateway
    end
  end

  private

  def build_forecast_request
    request_params = params.fetch(:forecast_request, {})

    @forecast_request = ForecastRequest.new(
      zip_code: request_params[:zip_code] || params[:zip_code],
      city: request_params[:city] || params[:city],
      days_from_now: request_params[:days_from_now] || params[:days_from_now] || params[:days]
    )
  end

  def cache_key_for(location)
    scope = @forecast_request.using_zip? ? "zip" : "city"
    "forecast_#{scope}_#{location}_d#{@forecast_request.days_from_now}"
  end
end
