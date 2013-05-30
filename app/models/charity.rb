class Charity < Neo4j::Rails::Model
  property :created_at
  property :updated_at
  property :name, :index => :exact
  property :ein, :index => :exact
  property :address
  property :city
  property :state
  property :zip
  property :ntee_core_code
  property :ntee_common_code

  validates :ein, :presence => true, :uniqueness => true
end
