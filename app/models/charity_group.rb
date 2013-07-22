# formerly 'endowment'
class CharityGroup < Neo4j::Rails::Model
  property :id
  property :created_at
  property :updated_at
  property :name, :index => :fulltext # describe this group "Help the Kids"

  has_n(:donations).to(Donation)
  has_n(:charities).to(Charity)

  validates :name, :presence => true,
                   :uniqueness => { :case_sensitive => false }
  validates :charities, :length => { :minimum => 1, :message => 'must have 1 or more charities' }


  class << self
    def new_with_charities(options = {})
      charity_ids = options.delete(:charity_ids) || []
      group = CharityGroup.new(options)

      charity_ids.each do |cid|
        group.charities << Charity.find!(cid) # FIXME find(array_of_ids) doesnt currently work
      end

      group
    end
  end # end self

  def as_json(options = {})
    super(:include =>[:charities])
  end

  def add(new_charity)
    group = CharityGroup.find(:id)
    group.charities.build(new_charity)
    group.charities
  end



end
