require 'bcrypt'

class Donor < ActiveRecord::Base
  include BCrypt

  has_many :donations, through: :payment_accounts
  has_many :payment_accounts

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :email, :presence => true,
                    :format => { :with => EMAIL_REGEX },
                    :uniqueness => { :case_sensitive => false }
  validates :password_hash, :presence => true
  validates :name, :presence => true

  class << self
    # needed because of the fulltext index
    def find_by_email(email)
      return nil if email.blank?
      # bug in neo4j.rb. search string with spaces must be in double qoutes
      self.find("email: \"#{email}\"", :type => :fulltext)
    end

    def authenticate(email, password)
      user = self.find_by_email(email)
      if user && user.password == password
        user
      else
        nil
      end
    end
  end # end self

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def as_json(options = {})
    super(:except => [:password_hash])
  end
end
