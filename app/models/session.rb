class Session < Neo4j::Rails::Model
  EXPIRES_IN_HOURS = 4
  has_one(:donor).to(Donor)
  property :created_at
  property :updated_at

  def expired?
    EXPIRES_IN_HOURS.hours.ago > created_at
  end

  def indicate_activity!
    self.update_attribute(:updated_at, Time.now)
  end

end
