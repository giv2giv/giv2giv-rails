class CreateEtradeTable < ActiveRecord::Migration
  def change
    create_table(:etrade) do |t|
      t.column :date, :datetime
      t.column :balance, :float
      t.column :cumulative_fees, :float
    end
  end
end
