class Fee < ActiveRecord::Base

  QUARTERLY_FEE = App.giv['quarterly_fee']

  class << self

    def calculate_fee

   		Etrade.authenticate

   		Share.compute_share_price

    	share_price = Share.last.fee_price

    	current_balance = Share.get_current_balance

    	shares_outstanding = Share.shares_outstanding

    	fee_amount = (BigDecimal(QUARTERLY_FEE.to_s) * BigDecimal(current_balance.to_s)).ceil2(2)

    	shares_subtracted = fee_amount / share_price

    	fee = Fee.new(
    		:amount => fee_amount,
    		:shares_outstanding => shares_outstanding,
    		:shares_subtracted => shares_subtracted,
        :transaction_id => nil,
        :cleared => false
    		)

    	fee.save!

    	Share.compute_share_price

    end

    def charge_fee
      fee = Fee.where(:cleared => false).last

      puts "In your browser, go to https://etrade.com and transfer $#{fee.amount} to your bank account."
      puts "Once you have done so, enter the transaction_id here : "

      transaction_id = $stdin.readline().chomp
      fee.transaction_id = transaction_id
      fee.cleared = true

      if fee.save
          puts "Fee has been updated !"
      else
          puts "Failed updating the Fee !"
      end
    end
  end

  private

end
