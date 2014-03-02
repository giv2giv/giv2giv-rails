class AddSlugToEndowments < ActiveRecord::Migration
  def change
    add_column :endowments, :slug, :string
    add_index :endowments, :slug, unique: true
  end
end
