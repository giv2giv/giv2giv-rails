# formerly 'endowment'
class CharityGroup < Neo4j::Rails::Model
  property :id
  property :created_at
  property :updated_at
  property :name, :index => :fulltext # describe this group "Help the Kids"

  has_n(:donations).to(Donation)
  has_n(:charities).to(Charity)

  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}
end
