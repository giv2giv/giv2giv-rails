require "spec_helper"

feature "Stripe Allocation" do
  scenario "One Time Charge" do
  	endowment = create(:endowment, name: "Sample Endowment")
  	endowment.charities << create(:charity)
  	donor = create(:donor, password: 'password')
  	payment_account = create(:payment_account, donor: donor)

  	Stripe::Customer.should_receive(:retrieve).once.with(payment_account.stripe_cust_id).and_return(mock(Stripe::Customer))

  	expected_charge_params = { amount: 12300, 
  							   currency: "usd", 
  							   description: "giv2giv.org donation to Sample Endowment",
                               customer: payment_account.stripe_cust_id }

   	mock_cust_charge = mock(Stripe::Charge)
   	mock_cust_charge.should_receive(:id).once.and_return(22)
  	Stripe::Charge.should_receive(:create).once.with(expected_charge_params).and_return(mock_cust_charge)


  	result = PaymentAccount.one_time_payment(123.00, endowment.id, donor.email, 'mock_stripeToken', payment_account.id, 'password')
  	result.should == {:message => "Success"}.to_json
  	subscription = donor.donor_subscriptions.first
  	subscription.stripe_subscription_id.to_i.should == 22
  	subscription.type_subscription.should == "one_time_payment"
  	subscription.gross_amount.to_i.should == 123
  end

  scenario "Monthly Subscription" do
  	pending
  end
  
end