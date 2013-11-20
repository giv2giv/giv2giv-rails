class AddAmountsToDonorGrants < ActiveRecord::Migration
  def change
    add_column :donor_grants, :gross_amount, :decimal, :precision => 30, :scale => 20
    add_column :donor_grants, :giv2giv_fee, :decimal, :precision => 30, :scale => 20
    add_column :donor_grants, :transaction_fee, :decimal, :precision => 30, :scale => 20
    add_column :donor_grants, :net_amount, :decimal, :precision => 30, :scale => 20
  end
end
