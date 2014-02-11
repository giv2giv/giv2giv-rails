require 'will_paginate/array'

class Api::EndowmentController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show]

  def global_balances(endowment)
    last_donation_price = Share.last.donation_price rescue 0.0
    endowment_share_balance = BigDecimal("#{endowment.donations.sum(:shares_added)}") - BigDecimal("#{endowment.donor_grants.sum(:shares_subtracted)}")

    global_balances = {
      "endowment_donor_count" => endowment.donations.count('donor_id', :distinct => true),
      "endowment_donations_count" => endowment.donations.count('id', :distinct => true),
      "endowment_donations" => (endowment.donations.sum(:gross_amount) * 10).ceil / 10.0,
      "endowment_transaction_fees" => (endowment.donations.sum(:transaction_fees) * 10).ceil / 10.0,
      "endowment_fees" => (endowment.donor_grants.sum(:giv2giv_fee) * 10).ceil / 10.0,
      "endowment_grants" => (endowment.donor_grants.sum(:gross_amount) * 10).ceil / 10.0,
      "endowment_share_balance" => ((endowment.donations.sum(:shares_added) - endowment.donor_grants.sum(:shares_subtracted)) * 10).ceil / 10.0,
      "endowment_balance" => (endowment_share_balance * last_donation_price * 10).ceil / 10.0

    }
  end

  def my_balances(endowment)
    if current_donor.present? && current_donor.id
      last_donation_price = Share.last.donation_price rescue 0.0
      if my_subscription_row = current_donor.donor_subscriptions.find_by_endowment_id(endowment.id)#.order('canceled_at')
        my_subscription_id = my_subscription_row.id
        my_subscription_amount = my_subscription_row.gross_amount
        my_subscription_type = my_subscription_row.type_subscription
        my_subscription_canceled_at = my_subscription_row.canceled_at
      else
        my_subscription_id = ""
        my_subscription_amount = ""
        my_subscription_type = ""
        my_subscription_canceled_at = ""
      end
      my_donations = current_donor.donations.where("endowment_id = ?", endowment.id)
      my_grants = current_donor.donor_grants.where("endowment_id = ?", endowment.id)

      my_donations_count = my_donations.count('id', :distinct => true)
      my_donations_amount = my_donations.sum(:gross_amount)
      my_donations_shares = my_donations.sum(:shares_added)

      my_grants_amount = my_grants.sum(:gross_amount)
      my_grants_shares = my_grants.sum(:shares_subtracted)

      my_balance_pre_investment = my_donations_amount - my_grants_amount
      my_endowment_share_balance = my_donations_shares - my_grants_shares

      my_endowment_balance = (my_endowment_share_balance * last_donation_price * 10).ceil / 10.0
      my_investment_gainloss = (my_endowment_balance - my_balance_pre_investment * 10).ceil / 10.0

      if defined?(:my_donations_count) && my_donations_count > 0
        my_investment_gainloss_percentage = (my_investment_gainloss / my_donations_amount * 100).round(3)
      else
        my_investment_gainloss_percentage = 0.0
      end


      {
        "my_subscription_id" => my_subscription_id,
        "my_subscription_amount" => my_subscription_amount.to_f,
        "my_subscription_type" => my_subscription_type,
        "my_subscription_canceled_at" => my_subscription_canceled_at,

        "my_donations_count" => my_donations_count,
        #"my_donations_shares" => my_donations_shares, # We should not expose shares to users -- too confusing
        "my_donations_amount" => my_donations_amount.to_f,
        #"my_grants_shares" => my_grants_shares,
        "my_grants_amount" => my_grants_amount.to_f,

        "my_balance_pre_investment" => my_balance_pre_investment.to_f,
        #"my_endowment_share_balance" => my_endowment_share_balance,

        "my_investment_gainloss" => my_investment_gainloss.to_f,
        "my_investment_gailoss_percentage" => my_investment_gainloss_percentage,
        "my_endowment_balance" => my_endowment_balance.to_f
      }
    else
      { "my_donations_count" => "0.0", "my_donations_amount" => "0.0", "my_grants_amount" => "0.0", "my_balance_pre_investment" => "0.0", "my_investment_gainloss" => "0.0", "my_investment_gainloss_percentage" => "0.0", "my_endowment_balance" => "0.0" }
    end
  end


  def index
    page = params[:page] || 1
    perpage = params[:per_page] || 10
    query = params[:query] || ""

    perpage=50 if perpage.to_i > 50

    endowments = []
    charities = []
    endowments_list = []

    #tags = Tag.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ])
    #tags.each do |tag|
      #tag.charities.each do |c|
        #charities << c
      #end
    #end

    #charities.each do |c|
      #endowments << c.endowments
    #end

    

    q = "%#{query}%"
    if q=="%%"
	    endowments = Endowment.where("visibility = ?", "public").order("RAND()").limit(perpage)
    else
      endowments = Endowment.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ])
    end

    endowments = endowments.compact.flatten.uniq.paginate(:page => page, :per_page => perpage)

    endowments.each do |endowment|
      endowment_hash = {
        "id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "name" => endowment.name,
        "description" => endowment.description,
        "visibility" => endowment.visibility,
        "minimum_donation_amount" => endowment.minimum_donation_amount,
        "my_balances" => my_balances(endowment),
        "global_balances" => global_balances(endowment),
        "charities" => endowment.charities              
      }
      endowments_list << endowment_hash
    end # endowment.each

    respond_to do |format|
      if endowments_list.present?
        format.json { render json: { :endowments => endowments_list } }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end

  end

  def create
    #params[:endowment] = { name: params[:name], minimum_donation_amount: params[:minimum_donation_amount], visibility: params[:visibility], description: params[:description] }

    respond_to do |format|

      if params[:minimum_donation_amount].to_f < 2.0
        format.json { render json: { :message => "Minimum donation at giv2giv is $2" }.to_json }
      end

      endowment = Endowment.new(params[:endowment])

      endowment.donor_id = current_session.donor_id
      if endowment.save
        if params.has_key?(:charities)
          charities = endowment.add_charity(params[:charities])
        end
        format.json { render json: endowment.to_json(:include => charities)}
      else
        format.json { render json: endowment.errors , status: :unprocessable_entity }
      end
    end
  end


  def show
    endowment = Endowment.find_by_id(params[:id])
    endowment_hash = {
      "id" => endowment.id,
      "created_at" => endowment.created_at,
      "updated_at" => endowment.updated_at,
      "name" => endowment.name,
      "description" => endowment.description,
      "visibility" => endowment.visibility,
      "minimum_donation_amount" => endowment.minimum_donation_amount,
      "my_balances" => my_balances(endowment),
      "global_balances" => global_balances(endowment),
      "charities" => endowment.charities
    }

    respond_to do |format|
      if endowment
        format.json { render json: { endowment: endowment_hash } }
      else
        format.json { head :not_found }
      end
    end
  end

  def rename_endowment
    endowment = Endowment.find_by_id(params[:id])
    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size >= 1
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        else
          endowment.update_attributes(params[:endowment])
          format.json { render json: { :message => "endowment has been updated", :endowment => params[:endowment] }.to_json }
        end
      end
    else
      render json: { :message => "You cannot edit this endowment" }.to_json
    end
  end

  def add_charity
    endowment = Endowment.find_by_id(params[:id])

    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size < 1
          endowment.add_charity(params[:charities])
          format.json { render json: { :message => "Charity has been added"}.to_json }
        else
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        end
      end #respond_to
    else
      render json: { :message => "You cannot edit this endowment" }.to_json
    end
  end

  def remove_charity
    endowment = Endowment.find_by_id(params[:id])
    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size < 1
          endowment.remove_charity(params[:id], params[:charity_id])
          format.json { render json: { :message => "Charity has been removed" }.to_json }
        else
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        end
      end #respond_to
    else
      render json: { :message => "You can edit this endowment" }.to_json
    end
  end

  def destroy
    endowment = Endowment.find_by_id(params[:id])
    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size < 1
          endowment.delete(params[:charity])
          format.json { render json: "Destroyed #{params[:charity]} record." }
        else
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        end
      end
    else
      render json: { :message => "You can edit this endowment" }.to_json
    end
  end

  def my_endowments
    endowments = current_donor.endowments
    endowments_list = []

    endowments.each do |endowment|
      endowment_hash = {
        "id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "name" => endowment.name,
        "description" => endowment.description,
        "visibility" => endowment.visibility,
        "minimum_donation_amount" => endowment.minimum_donation_amount,
        "my_balances" => my_balances(endowment),
        "global_balances" => global_balances(endowment),
        "charities" => endowment.charities              
      }
      endowments_list << endowment_hash
    end # endowment.each

    respond_to do |format|
      if endowments_list.present?
        format.json { render json: { :endowments => endowments_list } }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end
  end

end
