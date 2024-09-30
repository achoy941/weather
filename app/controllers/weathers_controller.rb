class WeathersController < ApplicationController

  WEATHER_EXPIRATION = 1800 # in seconds
  def search
    return if params[:address].blank?
    # params[:address]
    geo_location = fetch_coordinates(params[:address])
    unless geo_location
      # error page
      flash.now[:error] = 'Unable to find location'
      return
    end

    if geo_location['error']
      flash.now[:error] = 'API Error'
      return
    end

    first_result = geo_location['results'].first
    if first_result.dig('response', 'error')
      flash.now[:error] = 'Unable to find location'
      return
    end

    results = first_result.dig('response', 'results')
    location = results.first['location']
    zip_code = results.first['address_components']

    cached, weather = fetch_weather(zip_code, location)

    @weather = Weather.new(address: geo_location, current_weather: weather, cached: cached)
  end

  private

  # TODO: refactor all below to service

  def fetch_coordinates(address)
    geocode_key = ns_address(address)
    geocode = get_and_parse(geocode_key)
    unless geocode
      geocode_api = Geocodio::Gem.new(ENV['GEOCODIO_API_KEY'])
      geocode = geocode_api.geocode(params[:address])
      REDIS.set(geocode_key, geocode.to_json) unless geocode['error']
    end
    geocode
  end

  def ns_address(address)
    "ADDR:#{address}"
  end

  def fetch_weather(zip_code, location)
    weather_key = ns_weather(zip_code)
    weather = get_and_parse(weather_key)
    cached = !!weather
    unless weather
      api = OpenWeatherMap::API.new(ENV['OPENWEATHER_API_KEY'], 'en', 'imperial')
      weather_object = api.current([ location['lng'], location['lat'], ])
      weather = weather_object.as_json
      REDIS.set(weather_key, weather.to_json, ex: WEATHER_EXPIRATION)
    end
    [ cached, weather ]
  end

  def ns_weather(zip_code)
    "WEATHER:#{zip_code}"
  end

  def get_and_parse(key)
    rtn = REDIS.get(key)
    rtn ? JSON.parse(rtn) : rtn
  end

end