class RenameGrossAmountToGrantAmount < ActiveRecord::Migration
	def change
    rename_column :donor_grants, :gross_amount, :grant_amount
  end
end
