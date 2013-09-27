class Givshare < ActiveRecord::Base
  belongs_to :share
  belongs_to :charity_group
end