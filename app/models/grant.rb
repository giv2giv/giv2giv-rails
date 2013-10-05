class Grant < ActiveRecord::Base
  belongs_to :charity
  belongs_to :donor
end