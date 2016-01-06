class Grant < ActiveRecord::Base
  belongs_to :charity
  belongs_to :endowment
  belongs_to :donor

  VALID_STATUS = %w(pending_approval denied pending_acceptance accepted reclaimed failed cancelled)
  VALID_GRANT_TYPES = %w(endowed pass_thru)
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }
  validates :grant_type, :presence => true, :inclusion => { :in => VALID_GRANT_TYPES }

  GIV2GIV_GRANT_PERCENT = App.giv["quarterly_grant_percent"]
  MINIMUM_GRANT_AMOUNT = App.giv["minimum_grant_amount"]

  class << self

    def add_passthru_grant (subscription, original_donation_amount)
      #Called upon successful donation. Sells shares, makes grants to recipient charities

      if subscription.passthru_percent.nil?
        return
      end
        
      total_grants = 0.0

      grantee_charities = Endowment.find(subscription.endowment_id).charities || return

      share_price = Share.last.grant_price

      net_amount = grant_pre_fee_amount = (original_donation_amount * BigDecimal("#{subscription.passthru_percent}") / 100).floor2(2)

      amount_per_charity = (net_amount / grantee_charities.count).floor2(2)

      shares_per_charity = BigDecimal("#{amount_per_charity}") / BigDecimal("#{share_price}") # BigDecimal/BigDecimal, will be truncated by database

      ActiveRecord::Base.transaction do
        grants_array = []

        grantee_charities.each do |charity|
          grant = Grant.new(
                    :charity_id => charity.id,
                    :endowment_id => subscription.endowment_id,
                    :donor_id => subscription.donor_id,
                    :shares_subtracted => shares_per_charity,
                    :grant_amount => grant_pre_fee_amount,
                    :net_amount => net_amount,
                    :grant_type => 'pass_thru',
                    :status => 'pending_approval'
                    )
          if grant.save!
            grants_array << grant
            total_grants += grant.net_amount
          end
        end

        rounding_leftovers = net_amount-total_grants
        # Leave rounding leftovers in the DAF; the next share price calculation will adjust

      end

    end

    def grant_step_1
              
      endowments = Endowment.all

      #endowment_share_balance = BigDecimal("#{endowment.donations.sum(:shares_added)}") - BigDecimal("#{endowment.donor_grants.sum(:shares_subtracted)}")
      #endowment_grant_shares = (BigDecimal("#{endowment_share_balance}") * BigDecimal("#{GIV_GRANT_AMOUNT}")).round(SHARE_PRECISION)

      grant_share_price = Share.last.grant_price

      endowments.each do |endowment|

        charities = endowment.charities.where("active = ?", "true")

        next if charities.count < 1

        donated_shares = endowment.donations.group(:donor_id).sum(:shares_added)

        donated_shares.each do |donor_id, shares_donor_donated|

          amount_per_charity = 0
          shares_per_charity = 0

          shares_donor_granted = endowment.grants.where("donor_id = ? AND endowment_id = ? AND (status = ? OR status = ?)", donor_id, endowment.id, "accepted", "pending_acceptance").sum(:shares_subtracted)

          donor_share_balance = shares_donor_donated - shares_donor_granted # is BigDecimal - BigDecimal, so precision OK

          if donor_share_balance <= 0
            puts "donor_share_balance <= 0"
            next
          end

          preliminary_shares_per_charity = donor_share_balance * BigDecimal("#{GIV2GIV_GRANT_PERCENT}") / BigDecimal("#{charities.count}")
          
          net_amount = amount_per_charity = (preliminary_shares_per_charity * grant_share_price).floor2(2) # convert to dollars and cents
          shares_per_charity = amount_per_charity / grant_share_price # calculate shares subtracted

          charities.each do |charity|
            grant_record = Grant.new(
                        :donor_id => donor_id,
                        :endowment_id => endowment.id,
                        :charity_id => charity.id,
                        :shares_subtracted => shares_per_charity,
                        :grant_amount => amount_per_charity,
                        :net_amount => net_amount,
                        :grant_type => 'endowed',
                        :status => 'pending_approval'
                        )

            grant_record.save
          end

        end # donor_shares.each
      end # endowments.each       

      JobMailer.success_compute(App.giv["email_contact"]).deliver
    end # def grant_step_1

    def update_grant_status
      sent_grants = DwollaLibs.new.get_transactions_last_60_days

      sent_grants.each do |dwolla_grant|

        grant_status=nil

        case dwolla_grant["Status"]
          when 'processed'
            grant_status = "accepted"
          when 'pending'
            grant_status = 'pending_acceptance'
          else
            grant_status = dwolla_grant["Status"]
        end

        giv2giv_grants = Grant.where("transaction_id = ?", dwolla_grant["Id"])

        giv2giv_grants.each do |giv2giv_grant|
          
          giv2giv_grant.update_attributes(:status => grant_status)

          if grant_status == 'reclaimed' # Save the grant for the next cycle
            rollover_grant = giv2giv_grant.dup
            rollover_grant.transaction_id = nil
            rollover_grant.status='pending_approval'
            rollover_grant.save!
          end

        end
      end
    end

    def approve_pending_passthru_grants

      #if params[:password] == App.giv['giv_grant_password']

      total_grants = 0

      grants = Grant.select("charity_id AS charity_id, SUM(grant_amount) AS amount").where("grant_type = ? AND status = ?", "pass_thru", "pending_approval").group("charity_id")

      text = "Hi! This is an unrestricted grant from donors at the crowd-endowment service https://giv2giv.org  Contact hello@giv2giv.org with any questions or to find out how to create your own fund online."
      
      grants.each do |grant|
        charity = Charity.find(grant.charity_id)
        next if charity.email.nil?
        next if grant.amount < MINIMUM_GRANT_AMOUNT

        transaction_id = DwollaLibs.new.dwolla_send(charity.email, text, grant.amount)
        if transaction_id.is_a? Integer
          total_grants = total_grants + grant.amount
          Grant.where("status = ? AND charity_id=?", "pending_approval", grant.charity_id).update_all(:transaction_id => transaction_id, :status => 'pending_acceptance')
        else
          ap 'There was a problem.'
          ap transaction_id
        end
      end
      #client.update("This is the first test of the automated giv2giv tweeter. We're preparing to grant $" << total_grants.to_s)

      puts "Total amount sent: " << total_grants.to_s

    end

    def approve_pending_endowed_grants

      #if params[:password] == App.giv['giv_grant_password']

      total_grants = 0

      grants = Grant.select("charity_id AS charity_id, SUM(grant_amount) AS amount").where("grant_type = ? AND status = ?", "endowed", "pending_approval").group("charity_id")

      text = "Hi! This is an unrestricted grant from donors at https://giv2giv.org  Contact hello@giv2giv.org with any questions or to learn how to create your own fund."
      
      grants.each do |grant|
        charity = Charity.find(grant.charity_id)
        next if charity.email.nil?
        next if grant.amount < MINIMUM_GRANT_AMOUNT

        transaction_id = DwollaLibs.new.dwolla_send(charity.email, text, grant.amount)
        if transaction_id.is_a? Integer
          total_grants = total_grants + grant.amount
          Grant.where("status = ? AND charity_id=?", "pending_approval", grant.charity_id).update_all(:transaction_id => transaction_id, :status => 'pending_acceptance')
        else
          ap 'There was a problem.'
          ap transaction_id
        end
      end
      #client.update("This is the first test of the automated giv2giv tweeter. We're preparing to grant $" << total_grants.to_s)

      puts "Total amount sent: " << total_grants.to_s

    end

  end # end self
end
