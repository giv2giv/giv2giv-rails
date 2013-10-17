class Api::DonorsController < Api::BaseController
  skip_before_filter :require_authentication, :only => :create

  def create
    donor = Donor.new(params[:donor])
    donor.type_donor = "registered"
    donor.password = secure_password(params[:password])
    respond_to do |format|
      if donor.save
        format.json { render json: donor, status: :created }
      else
        format.json { render json: donor.errors, status: :unprocessable_entity }
      end
    end
  end

  def balance_information
    share_added = BigDecimal("#{current_donor.donations.sum(:shares_added)}") - BigDecimal("#{current_donor.grants.sum(:shares_subtracted)}")
    donor_balance = ((BigDecimal("#{share_added}") * BigDecimal("#{Share.last.donation_price}")) * 10).ceil / 10.0
    total_donations = current_donor.donations.sum(:amount)
    total_grants = ((Share.last.grant_price * current_donor.donations.sum(:shares_added)) * App.giv["giv_grant_amount"]).round(2)
    render json: {:balance => donor_balance, :total_donations => total_donations, :total_grants => total_grants}.to_json    
  end

  def update
    donor = current_donor

    respond_to do |format|
      if donor && donor.update_attributes(params[:donor])
        format.json { render json: donor }
      else
        format.json { render json: donor.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: current_donor }
    end
  end

end
