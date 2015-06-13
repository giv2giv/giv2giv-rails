class AllowNullEndowmentId < ActiveRecord::Migration
  def change
    change_column_null :donations, :endowment_id, true
  end
end
