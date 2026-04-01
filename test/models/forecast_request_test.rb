require "test_helper"

class ForecastRequestTest < ActiveSupport::TestCase
  test "rejects non-numeric days_from_now" do
    request = ForecastRequest.new(zip_code: "90001", days_from_now: "tomorrow")

    assert_not request.valid?
    assert_includes request.errors[:days_from_now], "is not a number"
  end

  test "accepts blank days_from_now as today" do
    request = ForecastRequest.new(zip_code: "90001", days_from_now: "")

    assert request.valid?
    assert_equal 0, request.days_from_now
  end
end
