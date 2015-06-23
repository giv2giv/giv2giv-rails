class Grant < ActiveRecord::Base
  belongs_to :charity
  belongs_to :endowment
  belongs_to :donor

  VALID_STATUS = %w(pending_approval denied pending_acceptance accepted reclaimed failed canceled)
  VALID_GRANT_TYPES = %w(endowed pass_thru)
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }
  validates :grant_type, :presence => true, :inclusion => { :in => VALID_GRANT_TYPES }

  GIV2GIV_PASSTHRU_FEE = App.giv["passthru_fee"]

  class << self

    def add_passthru_grant (subscription, original_donation_amount)
      #Called upon successful donation. Sells shares, makes grants to recipient charities

      total_grants = 0.0

      grantee_charities = Endowment.find(subscription.endowment_id).charities || return

      share_price = Share.last.grant_price

      grant_pre_fee_amount = (original_donation_amount * BigDecimal("#{subscription.passthru_percent}") / 100).floor2(2)

      giv2giv_fee = (grant_pre_fee_amount * GIV2GIV_PASSTHRU_FEE).floor2(2)

      grant_amount = (grant_pre_fee_amount - giv2giv_fee).floor2(2)

      amount_per_charity = (grant_amount / grantee_charities.count).floor2(2)

      shares_per_charity = BigDecimal("#{amount_per_charity}") / share_price # BigDecimal/BigDecimal, truncated by database

      ActiveRecord::Base.transaction do
        grants_array = []

        grantee_charities.each do |charity|
          grant = Grant.new(
                    :charity_id => charity.id,
                    :endowment_id => subscription.endowment_id,
                    :donor_id => subscription.donor_id,
                    :shares_subtracted => shares_per_charity,
                    :grant_amount => amount_per_charity,
                    :giv2giv_fee => giv2giv_fee,
                    :grant_type => 'pass_thru',
                    :status => 'pending_approval'
                    )
          if grant.save
            grants_array << grant
            total_grants += grant.grant_amount
          end
        end

        rounding_leftovers = half_donation_amount-total_grants
        # Leave rounding leftovers in the DAF

        Grant.process_passthru_grants()

      end

    end

    def process_passthru_grants()

      grants = Grant.joins(:charity).select("grants.id, charity_id, sum(grant_amount), email, grant_threshold").where("status =?", 'pending_approval').group("charity_id").having("sum(grant_amount) > charities.grant_threshold")

      grants.each do |grant|
        next if !grant.email

        net_amount = grant.grant_amount - grant.giv2giv_fee

        text = "Hi! This is an unrestricted grant from donors at the crowd-endowment service giv2giv.org  Half goes directly to you, half is invested and will be granted later.  Contact hello@giv2giv.org with any questions or to find out how to partner with us."

        transaction_id = DwollaLibs.new.dwolla_send(charity.email, text, net_amount)

        transaction_details = DwollaLibs.new.get_detail_transaction(transaction_id)

        if transaction_id.is_a? Integer
          grant.transaction_id=transaction_id
          grant.transaction_fee=transaction_details['Fees']

          case transaction_details["Status"]
            when 'processed'
              status = "accepted"
              cleared = true
            when 'pending'
              status = 'pending_acceptance'
              cleared=false
            else
              status = transaction_details["Status"]
              cleared=false
          end

          grant.status=status
          grant.net_amount = net_amount
          
          if grant.save!
            # Create funds in-transit record for etrade-to-dwolla
            TransitFund.create(
              transaction_id: transaction.id,
              source: "etrade",
              destination: "dwolla",
              amount: net_amount,
              cleared: cleared
            )
          end
        else
          raise 'Oops, Dwolla ID not available!'
        end

      end #grants_array.each
    end
  end # end self
end