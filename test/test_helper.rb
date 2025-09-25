ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "net/http"

module TestHelpers
  module HttpStub
    def with_http_response(response)
      http_singleton = Net::HTTP.singleton_class
      original = Net::HTTP.method(:get_response)

      http_singleton.define_method(:get_response) do |*args, **kwargs, &block|
        response
      end

      yield
    ensure
      http_singleton.define_method(:get_response) do |*args, **kwargs, &block|
        original.call(*args, **kwargs, &block)
      end
    end
  end

  module ApiServiceStub
    def with_api_service(result: nil, error: nil)
      original = ExternalApiService.method(:new)

      ExternalApiService.define_singleton_method(:new) do |*args, **kwargs|
        StubbedExternalApiService.new(result:, error:)
      end

      yield
    ensure
      ExternalApiService.define_singleton_method(:new) do |*args, **kwargs|
        original.call(*args, **kwargs)
      end
    end

    class StubbedExternalApiService
      def initialize(result:, error:)
        @result = result
        @error = error
      end

      def fetch_weather(query:, days: nil)
        raise(@error.is_a?(Class) ? @error.new : @error) if @error
        @result
      end
    end
  end
end

module ActiveSupport
  class TestCase
    include TestHelpers::HttpStub
    include TestHelpers::ApiServiceStub

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end
