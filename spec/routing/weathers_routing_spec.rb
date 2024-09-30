require 'rails_helper'

describe 'WeathersController', type: :routing do
  context 'routing' do
    it "recognizes and generates #search for GET /weathers/search(.:format)" do
      expect({:get => "/weathers/search"}).
        to route_to(
             :controller => "weathers",
             :action => "search",
           )
    end

    it "recognizes and generates #search for POST /weathers/search(.:format)" do
      expect({:post => "/weathers/search"}).
        to route_to(
             :controller => "weathers",
             :action => "search",
             )
    end
  end


end