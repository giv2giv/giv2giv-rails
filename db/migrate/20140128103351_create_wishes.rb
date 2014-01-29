class CreateWishes < ActiveRecord::Migration
  def change
    create_table :wishes do |t|
      t.integer :donor_id
      t.text :page
      t.text :wish_text

      t.timestamps
    end
  end
end
