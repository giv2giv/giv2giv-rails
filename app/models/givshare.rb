class Givshare < ActiveRecord::Base
  belongs_to :share
  belongs_to :donor
  belongs_to :charity_group

  with_options :presence => true do |givshare|
    givshare.validates :donor_id
    givshare.validates :charity_group_id
  end

end