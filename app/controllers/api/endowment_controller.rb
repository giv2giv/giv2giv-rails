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
    group = Endowment.new(params[:endowment])

    group.donor_id = current_session.session_id
    respond_to do |format|
      if group.save
        if params.has_key?(:charity_id)
          charities = group.add_charity(params[:charity_id])
        end
        format.json { render json: group.to_json(:include => charities)}
      else
        format.json { render json: group.errors , status: :unprocessable_entity }
      end
    end
  end

  def my_balances(endowment)
    unless current_donor.blank?
      last_donation_price = Share.last.donation_price rescue 0.0
      my_donations_amount = current_donor.donations.where("endowment_id = ?", endowment.id).sum(:gross_amount)
      my_grants_shares = ((current_donor.charity_grants.where("endowment_id = ?", endowment.id).sum(:shares_subtracted)) * 10).ceil / 10.0
      my_grants_amount = ((current_donor.donor_grants.where("endowment_id = ?", endowment.id).sum(:shares_pending)) * 10).ceil / 10.0
      my_donations_shares = ((current_donor.donations.where("endowment_id = ?", endowment.id).sum(:shares_added)) * 10).ceil / 10.0
      my_balance_pre_investment = my_donations_amount - my_grants_amount
      my_endowment_share_balance = my_donations_shares - my_grants_shares
      my_endowment_balance = ((my_endowment_share_balance * last_donation_price) * 10).ceil / 10.0
      my_investment_gainloss = my_endowment_balance - my_balance_pre_investment

      {
        "my_donations_count" => current_donor.donations.where("endowment_id = ?", endowment.id).count('id', :distinct => true),
        "my_donations_shares" => my_donations_shares,
        "my_donations_amount" => my_donations_amount,
        "my_grants_shares" => my_grants_shares,
        "my_grants_amount" => my_grants_amount,

        "my_balance_pre_investment" => my_balance_pre_investment,
        "my_endowment_share_balance" => my_endowment_share_balance,
        "my_endowment_balance" => my_endowment_balance,

        "my_investment_gainloss" => my_investment_gainloss,
        "my_investment_gailoss_percentage" => (my_investment_gainloss / my_donations_amount * 100).round(3)
      }
    else
      { "my_donations_count" => "0.0", "my_donations_shares" => "0.0", "my_donations_amount" => "0.0", "my_grants_shares" => "0.0", "my_grants_amount" => "0.0", "my_balance_pre_investment" => "0.0", "my_endowment_share_balance" => "0.0", "my_endowment_balance" => "0.0", "my_investment_gainloss" => "0.0", "my_investment_gainloss_percentage" => "0.0" }
    end
  end

  def global_balances(endowment)
    last_donation_price = Share.last.donation_price rescue 0.0
    endowment_share_balance = BigDecimal("#{endowment.donations.sum(:shares_added)}") - BigDecimal("#{endowment.charity_grants.sum(:shares_subtracted)}")
    endowment_grants = endowment.charity_grants.sum(:gross_amount)

    global_balances = {
      "endowment_donor_count" => endowment.donations.count('donor_id', :distinct => true),
      "endowment_donations_count" => endowment.donations.count('id', :distinct => true),
      "endowment_donations" => endowment.donations.sum(:gross_amount),
      "endowment_transaction_fees" => endowment.donations.sum(:transaction_fees),
      "endowment_fees" => endowment.donations.sum(:gross_amount),
      "endowment_grants" => endowment_grants,
      "endowment_share_balance" => ((endowment.donations.sum(:shares_added) - endowment.charity_grants.sum(:shares_subtracted)) * 10).ceil / 10.0,
      "endowment_balance" => ((endowment_share_balance * last_donation_price) * 10).ceil / 10.0
    }
  end


  def show
    endowment = Endowment.find(params[:id])

    respond_to do |format|
      if endowment
        format.json { render json: { endowment: endowment, my_balances: my_balances(endowment), global_balances: global_balances(endowment) } }
      else
        format.json { head :not_found }
      end
    end
  end

  def rename_endowment
    endowment = Endowment.find(params[:id])
    if (endowment.donor_id.to_s.eql?(current_session.session_id))
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
    group = Endowment.find(params[:id])

    if (group.donor_id.to_s.eql?(current_session.session_id))
      respond_to do |format|
        if group.donations.size < 1
          group.add_charity(params[:charity_id])
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
    group = Endowment.find(params[:id])
    if (group.donor_id.to_s.eql?(current_session.session_id))
      respond_to do |format|
        if group.donations.size < 1
          group.remove_charity(params[:id], params[:charity_id])
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
    group = Endowment.find(params[:id])
    if (group.donor_id.to_s.eql?(current_session.session_id))
      respond_to do |format|
        if group.donations.size < 1
          group.delete(params[:charity])
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
