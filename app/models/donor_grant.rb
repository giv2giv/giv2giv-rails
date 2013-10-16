class DonorGrant < ActiveRecord::Base
  belongs_to :charity
  belongs_to :charity_group
  belongs_to :donor
end