class RemoveDateFromGrants < ActiveRecord::Migration
  def up
    remove_column :grants, :date
  end

  def down
    add_column :grants, :date
  end
end
