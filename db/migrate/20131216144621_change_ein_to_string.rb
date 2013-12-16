class ChangeEinToString < ActiveRecord::Migration
  def up
    change_column :charities, :ein, :string
  end

  def down
    change_column :charities, :ein, :int
  end
end
