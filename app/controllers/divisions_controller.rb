class DivisionsController < ApplicationController
	def index
		@divisions = Division.all.resources
	end

	def index_by_house
		house_id = params[:house_id]
		house_uri = "http://data.parliament.uk/resource/#{house_id}"
		@house = House.find(house_uri)
		@divisions = Division.find_by_house(house_uri)
		render 'index_by_house'
	end
end
