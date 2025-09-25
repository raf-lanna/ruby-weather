class ForecastRequest
  include ActiveModel::Model

  CACHE_MSG = "This forecast came from cache and may be up to 30 minutes old.".freeze
  NOT_FOUND_CODE = 1006.freeze
  RESPONSE_CODE_1006 = "We couldn't find a location with those details. Please check the ZIP code or city name.".freeze
  TRY_AGAIN_MSG = "We couldn't fetch the forecast right now. Please try again shortly.".freeze

  attr_accessor :zip_code, :city
  attr_reader :days_from_now

  validates :days_from_now, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 5
  }
  validate :zip_or_city_presence
  validate :zip_code_format

  def initialize(attributes = {})
    super
    self.zip_code = attributes&.dig(:zip_code)
    self.city = attributes&.dig(:city)
    self.days_from_now = attributes&.dig(:days_from_now)
  end

  def zip_code=(value)
    @zip_code = value.to_s.strip
  end

  def city=(value)
    @city = value.to_s.strip
  end

  def days_from_now=(value)
    @days_from_now = value.present? ? value.to_i : 0
  end

  def normalized_zip_code
    return "" if zip_code.blank?

    digits = zip_code.delete("^0-9")
    if digits.length == 5
      digits
    elsif digits.length == 9
      "#{digits[0..4]}-#{digits[5..8]}"
    else
      zip_code
    end
  end

  def valid_zip_code?
    return false if zip_code.blank?

    digits = zip_code.delete("^0-9")
    (digits.length == 5 || digits.length == 9) &&
      (zip_code.match?(/\A\d{5}\z/) || zip_code.match?(/\A\d{5}-\d{4}\z/))
  end

  def location
    return normalized_zip_code if valid_zip_code?

    city
  end

  def using_zip?
    valid_zip_code?
  end

  private

  def zip_or_city_presence
    return if zip_code.present? || city.present?

    errors.add(:base, "Enter a ZIP code or city to check the forecast.")
  end

  def zip_code_format
    return if zip_code.blank?

    unless valid_zip_code?
      errors.add(:base, "Enter a valid US ZIP code (12345 or 12345-6789).")
    end
  end
end
