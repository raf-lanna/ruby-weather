class WeatherController < ApplicationController
  before_action :build_forecast_request

  def index; end

  def forecast
    unless @forecast_request.valid?
      flash.now[:alert] = @forecast_request.errors.full_messages.first
      render :index, status: :unprocessable_entity
      return
    end

    begin
      result = forecast_fetcher.call(request: @forecast_request)
      @forecast = result.forecast
      flash.now[:notice] = ForecastRequest::CACHE_MSG if result.cache_hit
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

  def forecast_fetcher
    @forecast_fetcher ||= Forecasts::FetchForecast.new
  end

  def build_forecast_request
    request_params = params.fetch(:forecast_request, {})

    @forecast_request = ForecastRequest.new(
      zip_code: request_params[:zip_code] || params[:zip_code],
      city: request_params[:city] || params[:city],
      days_from_now: request_params[:days_from_now] || params[:days_from_now] || params[:days]
    )
  end
end
