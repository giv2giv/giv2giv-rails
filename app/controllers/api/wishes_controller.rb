class Api::WishesController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:create, :show, :random]

  def create

    wish=Wish.new(params[:wish])

    if current_donor
      wish.donor_id = current_donor.id
    end

    respond_to do |format|
      if wish.save
        format.json { render json: wish, status: :created }
      else
        format.json { render json: wish.errors , status: :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: Wish.find_by_id(params[:id]) }
    end
  end

  def random
    respond_to do |format|
      format.json { render json: Wish.order("RAND()").limit(1) }
    end
  end

end
