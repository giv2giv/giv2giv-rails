class Donation < Neo4j::Rails::Model
  property :created_at
  property :updated_at
  property :amount
  property :transaction_id # from 3rd party
  property :transaction_processor # dwolla, paypal, whatever else we support

  has_one(:donor).from(Donor, :donations) # belongs_to....
  has_one(:charity_group).from(CharityGroup, :donations)

  validates :amount, :presence => true
  validates :transaction_id, :presence => true
  validates :transaction_processor, :presence => true
  validates :donor, :presence => true
end
