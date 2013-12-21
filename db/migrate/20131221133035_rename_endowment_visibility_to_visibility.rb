class RenameEndowmentVisibilityToVisibility < ActiveRecord::Migration
  def change
      rename_column :endowments, :endowment_visibility, :visibility
  end
end
