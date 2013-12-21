require 'spec_helper'

describe PaymentAccount do

  describe "validations" do
    it "should not be valid if requires_reauth is true" do
      pa = build(:payment_account, requires_reauth: true)
      pa.should_not be_valid
      pa.should have(1).error_on(:requires_reauth)
      pa.requires_reauth = false
      pa.should be_valid
    end

    it "should set requires_reauth before create if requires_reauth not specified" do
      pa = build(:payment_account)
      pa.should be_valid
      pa.requires_reauth.should == false
    end

    it "should require processor" do
      pa = build(:payment_account, processor: nil)
      pa.should_not be_valid
      pa.should have(2).error_on(:processor)
      pa.processor = 'stripe'
      pa.should be_valid
    end

    it "should be valid processor" do
      processor = 'yoga'
      PaymentAccount::VALID_PROCESSORS.should_not include(processor)
      pa = build(:payment_account, processor: processor)
      pa.should_not be_valid
      pa.should have(1).error_on(:processor)
      pa.processor = 'stripe'
      pa.should be_valid
    end

    it "should downcase processor" do
      processor = 'StRIpe'
      pa = build(:payment_account, processor: processor)
      pa.should be_valid
      pa.processor.should == processor.downcase
    end

    it "should require donor" do
      pa = build(:payment_account)
      pa.donor = nil
      pa.should_not be_valid
      pa.should have(1).error_on(:donor)
      pa.donor = build(:donor)
      pa.should be_valid
    end

  end # end validations

  describe "donate" do
    pending "should raise an exception if payment account is not valid" do
      # PaymentAccount.any_instance.stub(:valid?).and_return(true)
      # Endowment.stub(:find).and_return(nil)
      # expect {PaymentAccount.one_time_payment(1, 1)}.to raise_error(EndowmentInvalid)
    end

    pending "should raise an exception if endowment is not valid" do
      # Endowment.stub(:find).and_return(build(:endowment))
      # Endowment.any_instance.stub(:valid?).and_return(false)
      # expect {PaymentAccount.one_time_payment(1, 100)}.to raise_error(PaymentAccountInvalid)
    end

    pending "should create donation on success" do
      # processor = 'stripe'
      # charity_id = 12191984
      # token = 'a_leet_token'
      # amount = 2.50
      # transaction_id = 191284
      # d = Donor.create(:email => 'pa_donor@ltc.com', :name => 'Asdf', :password => 'pass', :type_donor => "registered")
      # d.should be_valid

      # pa = d.payment_accounts.build(:processor => processor)
      # pa.should be_valid

      # Endowment.stub(:find).and_return(OpenStruct.new(:id => 1))
      # App.should_receive(:dwolla).at_least(2).times.and_return({'account_id' => 540})
      # expected_call = {:destinationId => App.dwolla['account_id'], :amount => amount.to_f}
      # Dwolla::Transactions.should_receive(:send).with(expected_call).and_return(transaction_id)
      # donation = PaymentAccount.one_time_payment(amount, charity_id)

      # donation.amount.should == amount
      # donation.transaction_processor.should == processor
      # donation.transaction_id.should == transaction_id
      # d.donations.should include(donation)
    end
  end # end donate

end
