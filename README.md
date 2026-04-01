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

The forecast flow was refactored with explicit SOLID responsibilities:

- **S (Single Responsibility)**:
  - `WeatherController` handles only HTTP concerns (request/response, status, flash).
  - `Forecasts::FetchForecast` handles orchestration (provider call + cache).
  - `Forecasts::CacheKey` handles cache-key generation only.
- **O (Open/Closed)**:
  - `Forecasts::FetchForecast` is extendable via injected collaborators (`weather_provider`, `cache`, `forecast_factory`) without changing service logic.
- **L (Liskov Substitution)**:
  - Any object implementing `fetch_weather`, `fetch`, and `call` contracts can replace default collaborators.
- **I (Interface Segregation)**:
  - The service depends on small interfaces per collaborator, not broad concrete APIs.
- **D (Dependency Inversion)**:
  - Core flow depends on abstractions (behavior contracts) and receives concrete implementations at boundaries.

Full documentation is available at [`docs/SOLID.md`](docs/SOLID.md).
