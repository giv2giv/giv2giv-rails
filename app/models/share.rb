require 'bigdecimal'

class Share < ActiveRecord::Base
  has_many :givshares
  validates :donor_id, :presence => true
  validates :charity_group_id, :presence => true

  def current_total_price
  #returns bigdecimal
    return Share.select(:count).map{|c| c.count.to_d}.sum
  end

  def current_price
    current_etrade_total = Etrade.get_net_account_value
    return current_etrade_total/Share.current_etrade_total.to_f
  end

end
