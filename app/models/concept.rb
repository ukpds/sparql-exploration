class Concept < QueryObject
	include Vocabulary

	def self.all_alphabetical
		result = self.query('
			PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
			PREFIX dcterms: <http://purl.org/dc/terms/>
			PREFIX parl: <http://data.parliament.uk/schema/parl#>
			CONSTRUCT {
			    ?concept
			        skos:prefLabel ?label .
			}
			WHERE {
			    SELECT ?concept ?label (COUNT(?contribution) AS ?count)
			    WHERE {
			        ?concept
						a skos:Concept ;
						skos:prefLabel ?label .
			        ?contribution
						dcterms:subject ?concept .
			    }
			    GROUP BY ?concept ?label
			    ORDER BY DESC(?count)
			    LIMIT 200
			}
			ORDER BY ?label
		')

	  	hierarchy = self.find_convert_to_hash(result)

		{ :graph => result, :hierarchy => hierarchy }
	end
	
	def self.most_popular_by_contribution
		result = self.query('
			PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
			PREFIX dcterms: <http://purl.org/dc/terms/>
			PREFIX parl: <http://data.parliament.uk/schema/parl#>
			CONSTRUCT {
			    ?concept
					a skos:Concept ;
			        skos:prefLabel ?label ;
			    	parl:count ?count .
			}
			WHERE {
			    SELECT ?concept ?label (COUNT(?contribution) AS ?count)
			    WHERE {
			        ?concept
						a skos:Concept ;
						skos:prefLabel ?label .
			        ?contribution
						dcterms:subject ?concept .
			    }
			    GROUP BY ?concept ?label
			    ORDER BY DESC(?count)
			    LIMIT 200
			}
		')

	  	hierarchy = self.all_convert_to_hash(result)

		{ :graph => result, :hierarchy => hierarchy }
	end

	def self.find(uri)
		result = self.query("
			PREFIX schema: <http://schema.org/>
			PREFIX parl: <http://data.parliament.uk/schema/parl#>
			PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
			PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
			PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
			PREFIX dcterms: <http://purl.org/dc/terms/>
			CONSTRUCT {
				<#{uri}>
					parl:label ?label ;
					parl:writtenQuestionCount ?writtenQuestionCount ;
					parl:oralQuestionCount ?oralQuestionCount ;
					parl:divisionCount ?divisionCount ;
        			parl:orderPaperItemCount ?orderPaperItemCount ;
        			parl:petitionCount ?petitionCount ;
        			parl:committeeCount ?committeeCount .
			}
			WHERE {
				SELECT ?label (COUNT(DISTINCT ?oralQuestion) AS ?oralQuestionCount) (COUNT(DISTINCT ?writtenQuestion) AS ?writtenQuestionCount) (COUNT(DISTINCT ?division) AS ?divisionCount) (COUNT(DISTINCT ?orderPaperItem) AS ?orderPaperItemCount) (COUNT(DISTINCT ?petition) AS ?petitionCount) (COUNT(DISTINCT ?committee) AS ?committeeCount)
				WHERE {
					{
						?concept
							skos:prefLabel ?label .
					}
					{
						?writtenQuestion
							a parl:WrittenParliamentaryQuestion ;
							dcterms:subject ?concept .
					}
					UNION
					{
						?oralQuestion
							a parl:OralParliamentaryQuestion ;
							dcterms:subject ?concept .
					}
					UNION
					{
						?division
							a parl:Division ;
							dcterms:subject ?concept .
					}
        			UNION
					{
						?orderPaperItem
							a parl:OrderPaperItem ;
							dcterms:subject ?concept .
					}
					UNION
					{
						?petition
							a parl:EPetition ;
							dcterms:subject ?concept .
					}
        			UNION
        			{
            			?committee
                			a parl:Committee ;
                			dcterms:subject ?concept . 
        			}
					FILTER(?concept = <#{uri}>)
				}
				GROUP BY ?label
			}
		")

		subject = RDF::URI.new(uri)

		label = self.get_object(result, subject, Parl.label).to_s
		oral_question_count = self.get_object(result, subject, Parl.oralQuestionCount).to_i
		written_question_count = self.get_object(result, subject, Parl.writtenQuestionCount).to_i
		division_count = self.get_object(result, subject, Parl.divisionCount).to_i
		order_paper_item_count = self.get_object(result, subject, Parl.orderPaperItemCount).to_i
		petition_count = self.get_object(result, subject, Parl.petitionCount).to_i
		committee_count = self.get_object(result, subject, Parl.committeeCount).to_i

		hierarchy =
			{
				:id => self.get_id(uri),
				:label => label,
				:oral_question_count => oral_question_count,
				:written_question_count => written_question_count,
				:division_count => division_count,
				:order_paper_item_count => order_paper_item_count,
				:petition_count => petition_count,
				:committee_count => committee_count
			}

		{ :graph => result, :hierarchy => hierarchy }
	end

	private

	def self.all_convert_to_hash(graph)
		graph.subjects(unique: true).map do |subject| 
			label = self.get_object(graph, subject, Skos.prefLabel).to_s
			count = self.get_object(graph, subject, Parl.count).to_i

			{
				:id => self.get_id(subject),
				:label => label,
				:count => count
			}
		end
	end

	def self.find_convert_to_hash(graph)
		graph.map do |statement| 
      		{
      		  :id => self.get_id(statement.subject),
      		  :label => statement.object.to_s
      		}
    	end
	end
end