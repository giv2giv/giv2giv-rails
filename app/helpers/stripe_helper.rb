module StripeHelper

  def send_funds_to_etrade
    amount_to_send = Stripe::Balance.retrieve["available"][0].amount

    if amount_to_send.to_i==0
      puts 'No funds available for transfer'
      return
    end

    transfer = Stripe::Transfer.create(
      :amount => (amount_to_send * 100).to_i, #sent in cents
      :currency => "usd",
      :recipient => "self",
      :statement_description => "#{Date.today} transfer to eTrade"
    )

    TransitFund.create(
      transaction_id: transfer.id,
      source: "stripe",
      destionation: "etrade",
      amount: transfer.amount,
      cleared: false
    )
   

  end
end