
class Weather
  include ActiveModel::Model

  attr_accessor :cached, :address, :current_weather
end