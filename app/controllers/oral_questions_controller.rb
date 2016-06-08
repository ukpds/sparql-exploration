class OralQuestionsController < ApplicationController

	def index
		@oral_questions = OralQuestion.all.limit(30).resources
	end

	def index_by_house
		house_id = params[:house_id]
		house_uri = "http://data.parliament.uk/resource/#{house_id}"
		@house = House.find(house_uri)
		@oral_questions = OralQuestion.find_by_house(house_uri)
		render 'index_by_house'
	end
end