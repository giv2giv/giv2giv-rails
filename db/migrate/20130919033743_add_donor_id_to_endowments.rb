class AddDonorIdToEndowments < ActiveRecord::Migration
  def change
    add_column :endowments, :donor_id, :integer
  end
end
