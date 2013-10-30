class DonorSubscription < ActiveRecord::Base
  belongs_to :endowment
  belongs_to :donor
end