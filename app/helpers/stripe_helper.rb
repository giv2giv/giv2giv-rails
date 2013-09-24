module StripeHelper

  require "stripe"

  protected
  
  def cancel_subscription(cust_id)
    cu = Stripe::Customer.retrieve(cust_id)
    cu.cancel_subscription
  end

end