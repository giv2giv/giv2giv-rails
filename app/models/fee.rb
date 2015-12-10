class Fee < ActiveRecord::Base

  GIV2GIV_FEE = App.giv['quarterly_fee']

  class << self

    def calculate_fee

   		Etrade.authenticate

   		CalculationShare::Calculation.compute_share_price

    	share_price = Share.last.fee_price

    	current_balance = CalculationShare::Calculation.get_current_balance

    	shares_outstanding = Share.shares_outstanding

    	fee_amount = (BigDecimal(GIV2GIV_FEE.to_s) * BigDecimal(current_balance.to_s)).ceil2(2)

    	shares_subtracted = fee_amount / share_price

    	fee = Fee.new(
    		:amount => fee_amount,
    		:shares_outstanding => shares_outstanding,
    		:shares_subtracted => shares_subtracted
    		)

    	fee.save!

    	CalculationShare::Calculation.compute_share_price

    end

  end
end
