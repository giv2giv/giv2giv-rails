class RenameGrantGiv2givFee < ActiveRecord::Migration
  def change
    rename_column :grants, :giv2giv_fee, :transaction_fee
  end
end
