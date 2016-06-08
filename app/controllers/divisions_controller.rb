class DivisionsController < ApplicationController
	def index
		@divisions = Division.all.resources
	end

	def index_by_house
		house_id = params[:house_id]
		house_uri = "http://data.parliament.uk/resource/#{house_id}"
		@house = House.find(house_uri)
		@divisions = Division.find_by_house(house_uri)
	end

	def index_by_concept
		concept_id = params[:concept_id]
		concept_uri = "http://data.parliament.uk/resource/#{concept_id}"
		@concept = Concept.find(concept_uri)
		@divisions = Division.find_by_concept(concept_uri)
	end
end
