class ExternalAccount < ActiveRecord::Base

  belongs_to :donor

  def self.create_with_omniauth(auth, donor_id)

    account = ExternalAccount.new(
      :donor_id => donor_id,
      :provider => auth["provider"],
      :uid => auth["uid"],
      :name => auth["extra"]["raw_info"]["name"],
      :oauth_token => auth["credentials"]["token"],
      :oauth_expires_at => Time.at(auth["credentials"]["expires_at"])
      )

    if account.save
      account
    else
      account.errors
    end

  end

end
