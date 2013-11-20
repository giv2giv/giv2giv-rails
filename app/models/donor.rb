class Donor < ActiveRecord::Base
  has_many :donations, through: :payment_accounts, dependent: :destroy
  has_many :payment_accounts, dependent: :destroy
  has_many :donor_grants, dependent: :destroy
  has_many :donor_subscriptions, dependent: :destroy
  has_many :endowments, dependent: :destroy

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :email, :presence => true,
  :format => { :with => EMAIL_REGEX },
  :uniqueness => { :case_sensitive => false }

  with_options :presence => true do |donor|
    donor.validates :password
    donor.validates :name
    donor.validates :type_donor
  end

  before_create { generate_token(:auth_token) }

  class << self
    # needed because of the fulltext index
    def find_by_email(email)
      return nil if email.blank?
      self.where(:email => email).last
    end

    def authenticate(email, password)
      user = self.find_by_email(email)
      if user && user.password == password.to_s
        user
      else
        nil
      end
    end
  end # end self

  def send_password_reset
    token = generate_token(:password_reset_token)
    self.expire_password_reset = Time.zone.now
    save!
    DonorMailer.forgot_password(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while Donor.exists?(column => self[column])
  end

  def as_json(options = {})
    # don't show password in response
    super(:except => [:password])
  end
end
