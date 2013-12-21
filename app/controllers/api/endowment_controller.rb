require 'will_paginate/array'

class Api::EndowmentController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show]

  def index
    page = params[:page] || 1
    perpage = params[:per_page] || 10
    query = params[:query] || ""

    perpage=50 if perpage.to_i > 50

    endowments = []
    charities = []

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
	Endowment.where("endowment_visibility = ?", "public").order("RAND()").limit(perpage).each do |row|
          endowments << row
        end
    else
        Endowment.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ]).each do |row|
          endowments << row
        end
    end

    results = endowments.compact.flatten.uniq.paginate(:page => page, :per_page => perpage)
    respond_to do |format|
      if !results.empty?
        format.json { render json: results }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end

  end

  def create
    params[:endowment] = { name: params[:name], minimum_donation_amount: params[:minimum_donation_amount], endowment_visibility: params[:endowment_visibility], description: params[:description] }
    endowment = Endowment.new(params[:endowment])

    endowment.donor_id = current_session.donor_id
    respond_to do |format|
      if endowment.save
        if params.has_key?(:charity_id)
          charities = endowment.add_charity(params[:charity_id])
        end
        format.json { render json: endowment.to_json(:include => charities)}
      else
        format.json { render json: endowment.errors , status: :unprocessable_entity }
      end
    end
  end

  def my_balances(endowment)
    if current_donor.present? && current_donor.id
      last_donation_price = Share.last.donation_price rescue 0.0
      my_donations_count = current_donor.donations.where("endowment_id = ?", endowment.id).count('id', :distinct => true)
      my_donations_amount = current_donor.donations.where("endowment_id = ?", endowment.id).sum(:gross_amount)
      my_grants_shares = ((current_donor.donor_grants.where("endowment_id = ?", endowment.id).sum(:shares_subtracted)) * 10).ceil / 10.0
      my_grants_amount = ((current_donor.donor_grants.where("endowment_id = ?", endowment.id).sum(:gross_amount)) * 10).ceil / 10.0
      my_donations_shares = ((current_donor.donations.where("endowment_id = ?", endowment.id).sum(:shares_added)) * 10).ceil / 10.0
      my_balance_pre_investment = my_donations_amount - my_grants_amount
      my_endowment_share_balance = my_donations_shares - my_grants_shares
      my_endowment_balance = ((my_endowment_share_balance * last_donation_price) * 10).ceil / 10.0
      my_investment_gainloss = my_endowment_balance - my_balance_pre_investment

      {
        "my_donations_count" => my_donations_count,
        #"my_donations_shares" => my_donations_shares, # We should not expose shares to users -- too confusing
        "my_donations_amount" => my_donations_amount,
        #"my_grants_shares" => my_grants_shares,
        "my_grants_amount" => my_grants_amount,

        "my_balance_pre_investment" => my_balance_pre_investment,
        #"my_endowment_share_balance" => my_endowment_share_balance,

        "my_investment_gainloss" => my_investment_gainloss,
        #"my_investment_gailoss_percentage" => (my_investment_gainloss / my_donations_amount * 100).round(3),
        "my_endowment_balance" => my_endowment_balance
      }
    else
      { "my_donations_count" => "0.0", "my_donations_amount" => "0.0", "my_grants_amount" => "0.0", "my_balance_pre_investment" => "0.0", "my_investment_gainloss" => "0.0", "my_investment_gainloss_percentage" => "0.0", "my_endowment_balance" => "0.0" }
    end
  end

  def global_balances(endowment)
    last_donation_price = Share.last.donation_price rescue 0.0
    endowment_share_balance = BigDecimal("#{endowment.donations.sum(:shares_added)}") - BigDecimal("#{endowment.donor_grants.sum(:shares_subtracted)}")

    global_balances = {
      "endowment_donor_count" => endowment.donations.count('donor_id', :distinct => true),
      "endowment_donations_count" => endowment.donations.count('id', :distinct => true),
      "endowment_donations" => endowment.donations.sum(:gross_amount),
      "endowment_transaction_fees" => endowment.donations.sum(:transaction_fees),
      "endowment_fees" => endowment.donor_grants.sum(:giv2giv_fee),
      "endowment_grants" => endowment.donor_grants.sum(:gross_amount),
      #"endowment_share_balance" => ((endowment.donations.sum(:shares_added) - endowment.donor_grants.sum(:shares_subtracted)) * 10).ceil / 10.0,
      "endowment_balance" => ((endowment_share_balance * last_donation_price) * 10).ceil / 10.0
    }
  end

  def show
    endowment = Endowment.find(params[:id])
    endowment_hash = {
      "id" => endowment.id,
      "created_at" => endowment.created_at,
      "updated_at" => endowment.created_at,
      "name" => endowment.name,
      "description" => endowment.description,
      "endowment_visibility" => endowment.endowment_visibility,
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
    endowment = Endowment.find(params[:id])
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
    endowment = Endowment.find(params[:id])

    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size < 1
          endowment.add_charity(params[:charity_id])
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
    endowment = Endowment.find(params[:id])
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
    endowment = Endowment.find(params[:id])
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


end
