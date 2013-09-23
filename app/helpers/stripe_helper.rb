module StripeHelper

  require "stripe"

  protected

  def retrieve_stripe_plan
    Stripe::Plan.all
  end

  def retrieve_customer_data(cust_id)
    Stripe::Customer.retrieve(cust_id)
  end
  
  def cancel_subscription(cust_id)
    cu = Stripe::Customer.retrieve(cust_id)
    cu.cancel_subscription
  end

end