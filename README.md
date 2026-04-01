# Ruby Weather

A Rails app for checking weather by US ZIP code or city using WeatherAPI.

## Getting Started

- Install dependencies:
  - `bundle install`
- Configure environment:
  - create a `.env` file with `WEATHER_API_KEY=...`
- Start the server:
  - `bin/rails server`

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
