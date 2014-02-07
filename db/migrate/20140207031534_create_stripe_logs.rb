class CreateStripeLogs < ActiveRecord::Migration
  def change
    create_table :stripe_logs do |t|
      t.string :type
      t.text :event

      t.timestamps
    end
  end
end
