# Ruby Weather

A Rails app for checking weather by US ZIP code or city using WeatherAPI.

## Getting Started

- Ruby version:
  - `7.2.2`
- Install dependencies:
  - `bundle install`
- Configure environment:
  - Create a `.env` file with `WEATHER_API_KEY=...`
- Start the server:
  - `bin/rails server`
- Open:
  - `http://127.0.0.1:3000/weather`

## Tests

- Full test suite:
  - `bin/rails test`
- Style checks:
  - `bundle exec rubocop`

## Architecture and SOLID

The app applies SOLID principles in the forecast flow:

- `WeatherController`: HTTP layer (input/output).
- `Forecasts::FetchForecast`: business-rule and cache orchestration.
- `Forecasts::CacheKey`: single responsibility for cache key generation.

Full documentation is available at [`docs/SOLID.md`](docs/SOLID.md).
