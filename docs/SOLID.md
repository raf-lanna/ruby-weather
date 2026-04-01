# SOLID in Ruby Weather

This document explains how SOLID principles were applied in the app.

## S — Single Responsibility Principle (SRP)

- `WeatherController` now handles only HTTP flow (validation, status, and flash).
- The logic for fetching forecasts, calculating API `days`, and caching responses was moved to `Forecasts::FetchForecast`.
- Cache key construction was isolated in `Forecasts::CacheKey`.

## O — Open/Closed Principle (OCP)

- `Forecasts::FetchForecast` accepts injectable dependencies:
  - `weather_provider`
  - `cache`
  - `forecast_factory`
- This allows behavior extension (for example, another provider, cache, or factory) without editing the main class.

## L — Liskov Substitution Principle (LSP)

- The service depends on behavior through an implicit contract (duck typing):
  - `weather_provider` must respond to `fetch_weather(query:, days:)`.
  - `cache` must respond to `fetch(key, expires_in:)`.
  - `forecast_factory` must respond to `call(response, day_offset)`.
- Any implementation that follows this contract can replace the current one.

## I — Interface Segregation Principle (ISP)

- Dependencies use small, focused interfaces:
  - the provider only needs `fetch_weather`.
  - the cache only needs `fetch`.
  - the factory only needs `call`.
- This avoids unnecessary coupling to large concrete classes.

## D — Dependency Inversion Principle (DIP)

- `Forecasts::FetchForecast` depends on behavioral abstractions, not fixed concrete implementations.
- In production, defaults use `ExternalApiService`, `Rails.cache`, and `Forecast`.
- In tests, the same service uses doubles/fakes without touching the real network.

## Tests added to support the design

- `test/services/forecasts/cache_key_test.rb`
- `test/services/forecasts/fetch_forecast_test.rb`

These tests guarantee:

- correct cache key generation by scope (zip/city),
- cache hit/miss behavior,
- correct `days` usage when requesting a future forecast.
