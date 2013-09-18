class Donor < ActiveRecord::Base
  has_many :donations, through: :payment_accounts
  has_many :payment_accounts

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :email, :presence => true,
                    :format => { :with => EMAIL_REGEX },
                    :uniqueness => { :case_sensitive => false }
  validates :password, :presence => true
  validates :name, :presence => true

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

  def as_json(options = {})
    # don't show password in response
    super(:except => [:password])
  end
end
