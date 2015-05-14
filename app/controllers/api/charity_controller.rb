class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show, :find_by_slug, :show_endowments, :near, :widget_data, :stripe]
  before_action :set_charity, :only => [:widget_data, :stripe]

  include CharityImport

  def index
    pagenum = params[:page] || 1
    perpage = params[:per_page] || 10
    perpage = 50 if perpage.to_i > 50
#    offset_count = (page.to_i-1)*perpage.to_i

    query = params[:query] || ""
    city = params[:city]

    charities_with_matching_tags = []
    charities_with_matching_name = []
    charity_list = []

    #let's not sqli ourselves in the API
    nameq = "%#{query}%"
    cityq = "%#{city}%"
    #q = q.gsub!(' ','%')
    
    if cityq == "%%"
      charities_with_matching_name = Charity.where("name LIKE ? AND active = 'true'", nameq)
    else
      charities_with_matching_name = Charity.where("name LIKE ? AND city LIKE ? AND active='true'", nameq, cityq)
    end

    #tag_limit = perpage - charities_with_matching_name.size
    #Tag.where("name LIKE ?", q).each do |t|
    #    next if charities_with_matching_tags.size > tag_limit
    #    charities_with_matching_tags << t.charities
    #end

    charities_with_matching_name.page(pagenum).per(perpage).each do |charity|

      #if current_donor && current_donor.id
        #my_balances = current_donor.my_balances(endowment.id)
      #end
      charity_hash = {
      "id" => charity.id,
      "created_at" => charity.created_at,
      "updated_at" => charity.updated_at,
      "ein" => charity.ein,
      "name" => charity.name.titleize,
      "address" => charity.address,
      "city" => charity.city.titleize,
      "state" => charity.state,
      "zip" => charity.zip,
      "latitude" => charity.latitude,
      "longitude" => charity.longitude,
      "tax_period" => charity.group_code,
      "asset_amount" => charity.group_code,
      "income_amount" => charity.group_code,
      "revenue_amount" => charity.revenue_amount,
      "slug" => charity.slug,
      "tags" => charity.tags.pluck(:name),
      "tagline" => charity.tagline,
      "description" => charity.description,
      "donor_count" => charity.donor_count,
      "supporting_endowments" => charity.endowments,
      "current_balance" => charity.current_balance,
      "pending_grants" => charity.pending_grants,
      "delivered_grants" => charity.delivered_grants
    }
      charity_list << charity_hash
    end # charity.each

    respond_to do |format|
      if charity_list.present?
        format.json { render json: { :charities => charity_list }.to_json }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end

  end

  def show
    charity = Charity.where("(id=? OR slug=?)", params[:id], params[:id]).last

    charity_hash = {
      "id" => charity.id,
      "created_at" => charity.created_at,
      "updated_at" => charity.updated_at,
      "ein" => charity.ein,
      "name" => charity.name.titleize,
      "address" => charity.address,
      "city" => charity.city.titleize,
      "state" => charity.state,
      "zip" => charity.zip,
      "latitude" => charity.latitude,
      "longitude" => charity.longitude,
      "tax_period" => charity.group_code,
      "asset_amount" => charity.group_code,
      "income_amount" => charity.group_code,
      "revenue_amount" => charity.revenue_amount,
      "slug" => charity.slug,
      "tags" => charity.tags.pluck(:name),
      "tagline" => charity.tagline,
      "description" => charity.description,
      "donor_count" => charity.donor_count,
      "supporting_endowments" => charity.endowments,
      "current_balance" => charity.current_balance,
      "pending_grants" => charity.pending_grants,
      "delivered_grants" => charity.delivered_grants
    }


    respond_to do |format|
      if charity
        format.json { render json: { :charity => charity_hash }.to_json }
      else
        format.json { head :not_found }
      end
    end
  end

  def autocomplete
    render json: Charity.search(params[:q], fields: [{name: :word_start}], limit: 30).map {|charity| {value: charity.name, id: charity.id}}
  end
  
  def find_by_slug
    charity = Charity.friendly.find(params[:slug])
    respond_to do |format|
      if charity
        format.json { render json: charity }
      else
        format.json { head :not_found }
      end
    end
  end

  def show_endowments
    charity = Charity.find(params[:id])
    respond_to do |format|
      if charity
        format.json { render json: charity.endowments}
      else
        format.json { head :not_found }
      end
    end
  end

  def near
    radius = (params[:radius] || 25).to_i
    charity_list=[]

    if radius > 100
      radius = 100
    end

    location_by_ip = request.location

    if location_by_ip.blank?
      params[:latitude] = '38.149576'
      params[:longitude] = '-79.0716958'
    end

    begin
      if params.has_key?(:latitude) && params.has_key?(:longitude)
        charities = Charity.near([params[:latitude].to_f, params[:longitude].to_f], radius, :order => "distance").limit(50)
      else
        charities = Charity.near([location_by_ip.latitude, location_by_ip.longitude], radius, :order => "distance").limit(50)
      end
      radius*=2
    end while charities.empty? && radius < 250

    charities.each do |charity|

      charity_hash = {
        "id" => charity.id,
        "created_at" => charity.created_at,
        "updated_at" => charity.updated_at,
        "ein" => charity.ein,
        "name" => charity.name.titleize,
        "address" => charity.address,
        "city" => charity.city.titleize,
        "state" => charity.state,
        "zip" => charity.zip,
        "latitude" => charity.latitude,
        "longitude" => charity.longitude,
        "tax_period" => charity.group_code,
        "asset_amount" => charity.group_code,
        "income_amount" => charity.group_code,
        "revenue_amount" => charity.revenue_amount,
        "slug" => charity.slug,
        "tags" => charity.tags.pluck(:name),
        "tagline" => charity.tagline,
        "description" => charity.description,
        "donor_count" => charity.donor_count,
        "supporting_endowments" => charity.endowments,
        "current_balance" => charity.current_balance,
        "pending_grants" => charity.pending_grants,
        "delivered_grants" => charity.delivered_grants
      }
      charity_list << charity_hash
    end # charity.each

    respond_to do |format|
      if charity_list.present?
        format.json { render json: { :charities => charity_list }.to_json }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end
  end

  def widget_data
     render json: @charity

  end

  def stripe
    amount =  params.fetch(:'giv2giv-amount') { raise 'giv2giv-amount required' }
    stripeToken = params.fetch(:'giv2giv-stripeToken') { raise 'giv2giv-stripeToken required' }

    amount = (amount.to_f * 100).to_i #make sure assume_fees is calculated correctly

    email = params[:'giv2giv-email'].present? ? params[:'giv2giv-email'] : createRandomEmail

    begin

    # Create a Customer
    customer = Stripe::Customer.create(
      :source => stripeToken,
      :email  => email,
      :description => "widget"
    )

    donor = Donor.where(:email => email).first_or_initialize

    if donor.id.nil?
      donor.name = 'Unknown'
      donor.password = createRandomEmail
      donor.accepted_terms = true
      donor.accepted_terms_on = DateTime.now
      donor.type_donor = 'anonymous'
      donor.save!
    end

    payment = PaymentAccount.new({:donor=>donor})
    payment.processor = 'stripe';
    payment.stripe_cust_id = customer.id
    payment.save!

# HERE
# expects type, amount, endowment_id

# Which endowment!?

    donation = payment.stripe_charge('single_donation',amount, @charity.id)

Rails.logger.debug 'hi3'

    transaction = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)

    gross_amount = BigDecimal(transaction.amount.to_s) / 100
    transaction_fee = BigDecimal(transaction.fee.to_s) / 100
    net_amount = BigDecimal(transaction.net.to_s) / 100
Rails.logger.debug 'hi'
    donation = Donation.add_donation(
      donor_id: donor.id,
      charity_id: @charty.id,
      transaction_id: transaction.id.to_s,
      gross_amount: gross_amount,
      transaction_fee: transaction_fee,
      net_amount: net_amount
    )
    Rails.logger.debug 'hi2'
    format.json { render :json => donation }
    

    #rescue Stripe::CardError => e
      # The card has been declined
    #rescue #ActiveRecord::ActiveRecordError #rescue most everything else
      # Problem with DB

    end

  end

  private
    def set_charity
      @charity=Charity.where("(id = ? OR slug = ?)", params[:id], params[:id]).last
    end

    def createRandomEmail
      require 'securerandom'
      SecureRandom.hex + "@giv2giv.org";
    end
end

