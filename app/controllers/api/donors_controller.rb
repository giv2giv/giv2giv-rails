class Api::DonorsController < Api::BaseController

  skip_before_filter :require_authentication, :only => :create

  def create
    logger.error "all params: #{params.inspect}"
    logger.error "donor params: #{params[:donor].inspect}"
    donor = Donor.new(params[:donor])

    respond_to do |format|
      if donor.save
        logger.error "in the donor save"
        format.json { render json: donor, status: :created }
      else
        logger.error "in the donor error errors: #{donor.errors.full_messages}"
        format.json { render json: donor.errors, status: :unprocessable_entity }
      end
    end
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
