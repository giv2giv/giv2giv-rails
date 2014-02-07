class StripeLog < ActiveRecord::Base
  attr_accessible :event, :type
end
