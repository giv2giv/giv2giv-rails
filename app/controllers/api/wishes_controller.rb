class Api::WishesController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:create, :show, :random]

  def create

    wish = Wish.new(wish_params)

    if current_donor.present? &&  current_donor.id
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

  private
    def wish_params
      params.require(:wish).permit(:page, :wish_text, :donor_id)
    end
  

end
