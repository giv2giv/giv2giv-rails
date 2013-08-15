require 'dwolla'

class ETrade
  # for one time donation
  def donate(amount, charity_group_id)
    raise PaymentAccountInvalid if !self.valid?
    raise CharityGroupInvalid if !(charity = CharityGroup.find(charity_group_id))
    raise AmountInvalid if amount.blank? || amount < 0

    Dwolla::token = token
    transaction_id = Dwolla::Transactions.send({:destinationId => App.dwolla['account_id'],
                                                :amount => amount.to_f,
                                                :pin => pin})

    # amount = amount after processing fee(s)
    donation = donor.donations.build(:amount => amount,
                                     :charity_group_id => charity.id,
                                     :transaction_id => transaction_id,
                                     :transaction_processor => processor)
    donation.save(false)
    donation
  end
private

  def set_requires_reauth
    # just being nice for create
    self.requires_reauth = false if !self.requires_reauth
    true
  end

  def downcase_processor
    # just being nice for create
    self.processor = self.processor.downcase if self.processor
    true
  end
end
