class AddMainEndowmentIdToCharity < ActiveRecord::Migration
  def change
    add_column :charities, :main_endowment_id, :integer
	end
end
