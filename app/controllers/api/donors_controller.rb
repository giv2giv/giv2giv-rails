class Api::DonorsController < Api::BaseController
  skip_before_filter :require_authentication, :only => :create

  def create
    donor = Donor.new(params[:donor])
    donor.password = secure_password(params[:password])
    respond_to do |format|
      if donor.save
        format.json { render json: donor, status: :created }
      else
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

  def send_mail
    DonorMailer.charge_success(self).deliver
  end

end
