class ShareObserver < ActiveRecord::Observer
  #def before_save(share)
  #  stripe_balance = Calculation.get_stripe_balance
  #  etrade_balance = Calculation.get_etrade_balance
  #  if (share.stripe_balance != stripe_balance) || (share.etrade_balance != stripe_balance)
  #  	#something
  #  else
  #  	share.save!
  #  end
  #end
end
