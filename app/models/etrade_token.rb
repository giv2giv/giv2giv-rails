class EtradeToken < ActiveRecord::Base
  with_options :presence => true do |etrade_token|
    etrade_token.validates :token
    etrade_token.validates :secret
  end
end