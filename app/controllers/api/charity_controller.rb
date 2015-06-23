class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show, :find_by_slug, :show_endowments, :near, :widget_data, :stripe, :dwolla, :dwolla_done]
  before_action :set_charity, :only => [:show, :widget_data, :stripe, :dwolla, :dwolla_done, :show_endowments]

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

    charity_hash = {
      "id" => @charity.id,
      "created_at" => @charity.created_at,
      "updated_at" => @charity.updated_at,
      "ein" => @charity.ein,
      "name" => @charity.name.titleize,
      "address" => @charity.address,
      "city" => @charity.city.titleize,
      "state" => @charity.state,
      "zip" => @charity.zip,
      "latitude" => @charity.latitude,
      "longitude" => @charity.longitude,
      "tax_period" => @charity.group_code,
      "asset_amount" => @charity.group_code,
      "income_amount" => @charity.group_code,
      "revenue_amount" => @charity.revenue_amount,
      "slug" => @charity.slug,
      "tags" => @charity.tags.pluck(:name),
      "tagline" => @charity.tagline,
      "description" => @charity.description,
      "donor_count" => @charity.donor_count,
      "supporting_endowments" => @charity.endowments,
      "current_balance" => @charity.current_balance,
      "pending_grants" => @charity.pending_grants,
      "delivered_grants" => @charity.delivered_grants
    }

    respond_to do |format|
      if @charity
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
    respond_to do |format|
      if @charity
        format.json { render json: @charity.endowments}
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

    email = params[:'giv2giv-email'].present? ? params.fetch(:'giv2giv-email') : createRandomEmail
    passthru_percent = params[:'giv2giv-passthru-percent'].chomp('%')

    Charity.transaction do
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

      endowment = Endowment.find_or_initialize_by(id: @charity.main_endowment_id)
      endowment.name = @charity.name.titleize
      endowment.visibility = 'public'
    
      if endowment.save!
        @charity.main_endowment_id = endowment.id
        @charity.save! if @charity.changed?
        donation = payment.stripe_charge(params.fetch(:'giv2giv-recurring'), amount, endowment.id, passthru_percent)
        render json: donation
      else
        render json: { :message => "Not found" }.to_json
      end
    
    end

  end

  def dwolla
    require 'dwolla'

    Dwolla::OffsiteGateway.clear_session

    # Set API credentials
    Dwolla::api_key = App.dwolla['api_key']
    Dwolla::api_secret = App.dwolla['api_secret']

    Dwolla::sandbox = true
    mail = params[:'giv2giv-email'].present? ? params[:'giv2giv-email'] : createRandomEmail

    # Where should Dwolla send the user after they check out or cancel?
    Dwolla::OffsiteGateway.redirect = App.giv['api_url'] + "/charity/#{@charity.id}/dwolla_done.json"
    Dwolla::OffsiteGateway.allowGuestCheckout = true
    Dwolla::OffsiteGateway.allowFundingSources = true

    # Add a product to the purchase order
    Dwolla::OffsiteGateway.add_product(@charity.name, "giv2giv donation to " + @charity.name, params[:'giv2giv-amount'].gsub(/[^\d\.]/, '').to_f, 1)

    # Generate a checkout URL payable to our Dwolla ID
    checkout_url = Dwolla::OffsiteGateway.get_checkout_url(App.dwolla['account_id'])
    redirect_to checkout_url
  end

  def dwolla_done

#callback comes in
#  create subscription
#  create grant, mark as 'pending'?


#receive webhook
#  mark as correct status
#  if !immediate, send pass-thru

    Dwolla::OffsiteGateway.clear_session

    # Set API credentials
    Dwolla::api_key = App.dwolla['api_key']
    Dwolla::api_secret = App.dwolla['api_secret']
    Dwolla::sandbox = App.dwolla['sandbox_mode']

=begin Callback params looks like:
      "signature"=>"77dbd9d237cc8bce5bd2425c2eb88b435752a788",
      "orderId"=>"",
      "amount"=>"5.00",
      "checkoutId"=>"3c98a679-2795-4dda-a0c2-6b712831c944",
      "status"=>"Completed",
      "clearingDate"=>"2015-02-11T02:27:37Z",
      "sourceEmail"=>"mblinn@gmail.com",
      "sourceName"=>"John Doe",
      "transaction"=>"834644",
      "destinationTransaction"=>"834643",
      "action"=>"dwolla_done",
      "controller"=>"charities",
      "id"=>"1"
=end

    transaction = Dwolla::OffsiteGateway.read_callback(params.to_json)
    email = transaction['sourceEmail']
    gross_amount = BigDecimal(transaction['amount'])
    
    #transaction_fee = gross_amount > 10 ? 0.25 : 0.0
    net_amount = gross_amount#- transaction_fee;
    
    begin

#Make donor

      donor = Donor.where(:email => params[:email]).first_or_initialize
      if donor.id.nil?
         donor.name = 'Unknown'
         donor.password = createRandomEmail
         donor.accepted_terms = true
         donor.accepted_terms_on = DateTime.now
         donor.type_donor = 'registered'
         donor.save!
       end
 
       payment = PaymentAccount.new({:donor=>donor})
       payment.processor = 'dwolla';
       payment.stripe_cust_id = customer.id
       payment.save!  
      

#Here do donor_subscription
      donor_subscription = DonorSubscription.new(
        donor_id: donor.id,
        payment_account_id: payment.id,
        charity_id: @charity.id,
        gross_amount: gross_amount
      )
      donor_subscription.save!

      redirect_to "http://cnn.com"

      rescue Dwolla::APIError => e
        Rails.logger.debug 'oops'
        # User pressed cancel
      rescue #ActiveRecord::ActiveRecordError #rescue most everything else
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

