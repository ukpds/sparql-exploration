class OralQuestion
  @@client = SPARQL::Client.new(DataDriven::Application.config.database)

  def self.all
    result = @@client.query("PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                            PREFIX schema: <http://schema.org/>
                            select ?question ?text where { 
                              ?question rdf:type <http://data.parliament.uk/schema/parl#OralParliamentaryQuestion>;
                                        schema:text ?text;
                            }")
    self.serialize(result)
  end

  def self.find(uri)
    result = @@client.query("PREFIX schema: <http://schema.org/>
                              PREFIX dcterms: <http://purl.org/dc/terms/>
                              PREFIX parl: <http://data.parliament.uk/schema/parl#>
                              select ?text ?date ?house ?member ?house_label ?member_name where { 
                                <#{uri}> schema:text ?text;
                                              dcterms:date ?date;
                                              parl:house ?house;
                                              parl:member ?member .
                                ?house <http://www.w3.org/2000/01/rdf-schema#label> ?house_label .
                                ?member schema:name ?member_name    
                            }")
    result.map do |solution| 
      Hashit.new(
      {
        :id => uri.to_s.split("/").last,
        :text => solution.text.to_s,
        :date => solution.date.to_s.to_datetime,
        :house => Hashit.new({ :id => solution.house.to_s.split("/").last, :label => solution.house_label.to_s }),
        :tablingMember => Hashit.new({ :id => solution.member.to_s.split("/").last, :name => solution.member_name.to_s})
      })
    end.first
  end

  def self.find_by_house(house_uri)
    result = @@client.query("PREFIX parl: <http://data.parliament.uk/schema/parl#>
                            PREFIX schema: <http://schema.org/>
                            select ?question ?text where { 
                                    ?question rdf:type parl:OralParliamentaryQuestion;
                                              parl:house <#{house_uri}>;
                                              schema:text ?text .
                            }")
    self.serialize(result)
  end

  def self.find_by_concept(concept_uri)
    result = @@client.query("PREFIX parl: <http://data.parliament.uk/schema/parl#>
                            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                            PREFIX dcterms: <http://purl.org/dc/terms/>
                            PREFIX schema: <http://schema.org/>
                            select ?question ?text where { 
                                    ?question rdf:type parl:OralParliamentaryQuestion;
                                              dcterms:subject <#{concept_uri}>;
                                              schema:text ?text .
                            }")
    self.serialize(result)
  end

  def self.find_by_person(person_uri)
    result = @@client.query("PREFIX parl: <http://data.parliament.uk/schema/parl#>
                            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                            PREFIX schema: <http://schema.org/>
                            select ?question ?text where { 
                                    ?question rdf:type parl:OralParliamentaryQuestion;
                                              parl:member <#{person_uri}>;
                                              schema:text ?text .
                            }")
    self.serialize(result)
  end

  private

  def self.serialize(data, id=nil)
    data.map do |solution| 
      id ||= solution.question
      Hashit.new(
      {
        :id => id.to_s.split("/").last,
        :text => solution.text.to_s
      })
    end
  end

end