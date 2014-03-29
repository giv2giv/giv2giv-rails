class ExternalAccounts < ActiveRecord::Base

  belongs_to :donor

  def self.create_with_omniauth(auth)
  Rails.logger.debug 'hi'
    create! do |account| # modify new account before it's saved, return new account
      account.donor_id = current_donor.id
      account.provider = auth["provider"]
      account.uid = auth["uid"]
      account.name = auth["account_info"]["name"]
      account.oauth_token = auth["credentials"]["token"]
      account.oauth_expires_at = Time.at(auth["credentials"]["expires_at"]
    end
  end

end