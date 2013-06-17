class Session < Neo4j::Rails::Model
  EXPIRES_IN_HOURS = 4

  property :token, :index => :exact
  property :created_at
  property :updated_at

  has_one(:donor).to(Donor)

  before_create :generate_token

  validates :donor, :presence => true

  def expired?
    EXPIRES_IN_HOURS.hours.ago > created_at
  end

  def indicate_activity!
    self.update_attribute(:updated_at, Time.now)
  end

  def as_json(options = {})
    super(:include =>[:donor])
  end

private

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64
      break random_token if !self.class.find_by_token(random_token) # make sure the generated token isn't already in use
    end
  end

end
