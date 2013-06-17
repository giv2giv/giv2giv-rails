class Api::SessionsController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:create,
                                                        :destroy]

  def create
    donor = Donor.authenticate(params[:email].to_s, params[:password].to_s)

    respond_to do |format|
      if donor
        sess = Session.create(:donor => donor)
        format.json { render json: sess, status: :created }
      else
        format.json { head :unauthorized }
      end
    end
  end

  def destroy
    current_session.destroy if current_session

    respond_to do |format|
      format.json { head :ok }
    end
  end

end
