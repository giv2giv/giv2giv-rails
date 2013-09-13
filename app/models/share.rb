
class Share < ActiveRecord::Base
  validates :donor_id, :presence => true
  validates :charity_group_id, :presence => true


end




