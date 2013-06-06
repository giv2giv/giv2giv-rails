require 'spec_helper'

describe PaymentAccount do

  valid_pa_attributes = {:processor => 'me',
                         :token => 'asdf',
                         :donor => Donor.new}

  before(:each) do
    @pa = PaymentAccount.new
  end

  describe "validations" do
    it "should not be valid if requires_reauth is true" do
      @pa.attributes = valid_pa_attributes.merge(:requires_reauth => true)
      @pa.should_not be_valid
      @pa.should have(1).error_on(:requires_reauth)
      @pa.requires_reauth = false
      @pa.should be_valid
    end

    it "should set requires_reauth before create if requires_reauth not specified" do
      @pa.attributes = valid_pa_attributes
      @pa.should be_valid
      @pa.requires_reauth.should == false
    end

    it "should require processor" do
      @pa.attributes = valid_pa_attributes.except(:processor)
      @pa.should_not be_valid
      @pa.should have(1).error_on(:processor)
      @pa.processor = 'me'
      @pa.should be_valid
    end

    it "should require token" do
      @pa.attributes = valid_pa_attributes.except(:token)
      @pa.should_not be_valid
      @pa.should have(1).error_on(:token)
      @pa.token = 'meeeeeeee'
      @pa.should be_valid
    end

    it "should require donor" do
      @pa.attributes = valid_pa_attributes.except(:donor)
      @pa.should_not be_valid
      @pa.should have(1).error_on(:donor)
      @pa.donor = Donor.new
      @pa.should be_valid
    end

  end # end validations

  describe "donate" do
    it "should raise an exception if payment account is not valid" do
      @pa.should_not be_valid
      expect {@pa.donate(1, 1)}.to raise_error(PaymentAccount::AccountInvalid)
    end

    it "should create donation on success" do
      processor = 'Tiger'
      charity_id = 12191984
      token = 'a_leet_token'
      amount = 2.50
      transaction_id = 191284
      d = Donor.create(:email => 'pa_donor@ltc.com', :name => 'Asdf', :password => 'pass')
      d.should be_valid

      pa = d.build_payment_account(:processor => processor, :token => token)
      pa.should be_valid

      App.should_receive(:dwolla).at_least(2).times.and_return({'account_id' => 540})
      expected_call = {:destinationId => App.dwolla['account_id'], :amount => amount.to_f, :pin => pa.pin}
      Dwolla::Transactions.should_receive(:send).with(expected_call).and_return(transaction_id)
      donation = pa.donate(amount, charity_id)

      donation.amount.should == amount
      donation.transaction_processor.should == processor
      donation.transaction_id.should == transaction_id
      d.donations.should include(donation)
    end
  end # end donate

end
