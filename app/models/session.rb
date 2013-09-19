class Session < ActiveRecord::Base
  belongs_to :donor, foreign_key: :session_id, class_name: "Donor"
  before_create :generate_token

  def as_json(options = {})
    super(:except => [:id])
  end

  protected

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Session.where(token: random_token).exists?
    end
  end
  
end