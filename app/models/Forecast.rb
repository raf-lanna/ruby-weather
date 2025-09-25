class Forecast
  attr_reader :location_name,
              :region,
              :country,
              :latitude,
              :longitude,
              :time_zone,
              :local_time,
              :temperature_c,
              :temperature_f,
              :humidity,
              :wind_kph,
              :wind_direction,
              :precip_inches,
              :visibility_miles,
              :uv_index,
              :last_updated,
              :condition_text,
              :condition_icon_url,
              :condition_code

  def self.from_api_response(response)
    location = response.fetch("location", {})
    current = response.fetch("current", {})

    new(location: location, current: current)
  end

  def initialize(location:, current:)
    condition = current.fetch("condition", {}) || {}

    @location_name = location["name"]
    @region = location["region"]
    @country = location["country"]
    @latitude = location["lat"]
    @longitude = location["lon"]
    @time_zone = location["tz_id"]
    @local_time = location["localtime"]

    @temperature_c = current["temp_c"]
    @temperature_f = current["temp_f"]
    @humidity = current["humidity"]
    @wind_kph = current["wind_kph"]
    @wind_direction = current["wind_dir"]
    @precip_inches = current["precip_in"]
    @visibility_miles = current["vis_miles"]
    @uv_index = current["uv"]
    @last_updated = current["last_updated"]

    raw_is_day = current.key?("is_day") ? current["is_day"] : nil
    @is_daytime = raw_is_day.nil? ? nil : raw_is_day.to_i == 1

    @condition_text = condition["text"]
    @condition_code = condition["code"]
    @condition_icon_url = normalize_icon_url(condition["icon"])
  end

  def location_label
    [ location_name, region, country ].compact.reject(&:blank?).join(", ")
  end

  def daytime?
    @is_daytime
  end

  def daylight_label
    daytime? ? "Daytime" : "Nighttime"
  end

  private

  def normalize_icon_url(icon)
    return if icon.blank?

    icon.start_with?("http") ? icon : "https:#{icon}"
  end
end
