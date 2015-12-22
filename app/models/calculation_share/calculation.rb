
module CalculationShare
  class Calculation

    class << self

      def project_amount (options = {})

        default_options = {
            :principal=>0,
            :monthly_addition=>0, 
            :years=>25, 
            :return_rate=>0.07
        }

        options = default_options.merge(options)

        principal = options[:principal]
        monthly_addition = options[:monthly_addition]
        years = options[:years]
        return_rate = options[:return_rate]

        amount_array = []
        total_donations = 0.0
        total_grants = 0.0
        total_fees = 0.0

        month = 1

        while month <= years * 12 do
          month = month + 1
          total_donations += monthly_addition
          principal += monthly_addition
          principal += principal * (return_rate / 12) 
          if month % 4 == 0
            grant_amount = principal * App.giv["quarterly_grant_percent"]
            total_grants += grant_amount
            fee_amount = principal * App.giv["quarterly_fee"]
            total_fees += fee_amount
            principal -= grant_amount
            principal -= fee_amount
          end
          if month % 12 == 0
            amount_hash = {
              "date" => Date.today + month.months,
              "total_donations" => total_donations.floor2(2),
              "total_grants" => total_grants.floor2(2),
              "total_fees" => total_fees.floor2(2),
              "balance" => principal.floor2(2)      
            }
            amount_array << amount_hash
          end

        end

        amount_array

      end


    end # end self
  end
end
