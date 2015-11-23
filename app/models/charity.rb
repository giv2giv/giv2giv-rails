class Charity < ActiveRecord::Base

  has_and_belongs_to_many :endowments
  has_and_belongs_to_many :tags
  has_many :grants
  
  geocoded_by :full_street_address
  #has_attached_file :image, styles: { small: "64x64", med: "100x100", large: "200x200" }
  
  searchkick word_start: [:name], callbacks: false# or use   callbacks: :async

  def search_data
    {
      name: name,
      secondary: secondary_name,
      city: city,
      state: state
    }
  end

  #geocode on save if address changed
  after_validation :geocode, if: ->(charity){ charity.address.present? and charity.address_changed? }
  #geocode on load if charity not yet geocoded
  after_find :geocode, if: ->(charity){ charity.address.present? and charity.latitude.nil? }
  after_initialize do |charity|
    if charity.latitude_changed?
      begin
        charity.save!
      rescue ActiveRecord::RecordInvalid => invalid
        puts charity
      end
    end
  end

  validates :ein, :presence => true, :uniqueness => true
  validates :name, :presence => true
  
  extend FriendlyId
  friendly_id :friendly_name, use: :slugged

  def should_generate_new_friendly_id?
    slug.blank? || name_changed?
  end

  def friendly_name
    case name
      when 'edit' then "#{name}-#{id}"
      else name
    end
  end

  def last_donation_price
    Share.last.donation_price.floor2(2) rescue 0.0
  end

  def donor_count
    count = 0
    self.endowments.each do |endowment|
      if endowment.donations.count > 0
        count += endowment.donations.select(:donor_id).distinct.count
      end
    end
    count
  end

  def share_balance
    my_shares = 0.0
    if self.endowments.count > 0
      self.endowments.each do |endowment|
        my_shares += endowment.share_balance / endowment.charities.count
      end
    end
    my_shares
  end

  def current_balance
    (share_balance * last_donation_price).floor2(2)
  end

  def pending_grants
    Grant.where("charity_id=? AND (status = ? OR status = ?)", self.id, 'pending_acceptance', 'pending_approval').sum(:grant_amount).to_f
  end

  def delivered_grants
    Grant.where("charity_id=? AND (status = 'accepted')", self.id).sum(:grant_amount).to_f
  end

  def full_street_address
    [self.address,self.city,self.state,self.zip].join(' ').squeeze(' ')
  end

  class << self

    def create_or_update(options = {})
      raise ArgumentError unless options[:ein].present? && options[:name].present?
      charity = Charity.where(:ein => options[:ein]).first_or_create
      charity.update_attributes(options.except(:ein))
      charity
    end

  end # end self



end
