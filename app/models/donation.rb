class Donation < Neo4j::Rails::Model
  property :created_at
  property :updated_at
  property :amount
  property :transaction_id # from dwolla

end
