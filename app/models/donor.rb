require 'bcrypt'

class Donor < Neo4j::Rails::Model
  include BCrypt

  property :name, :index => :fulltext
  property :email, :index => :fulltext # for case insensitive validation
  property :password_hash, :type => :string # includes version, cost, salt and password hash

  property :created_at
  property :updated_at
  property :facebook_id, :index => :exact
  property :address
  property :city
  property :state
  property :zip
  property :country
  property :phone_number

  has_n(:donations).to(Donation)
  has_one(:payment_account).to(PaymentAccount)

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :email, :presence => true, :format => {:with => EMAIL_REGEX}, :uniqueness => {:case_sensitive => false}
  validates :password_hash, :presence => true
  validates :name, :presence => true

  class << self
    # needed because of the fulltext index
    def find_by_email(email)
      Donor.find("email: #{email}", :type => :fulltext)
    end

    def authenticate(email, password)
      user = Donor.find_by_email(email)
      if user.password == password
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

end
