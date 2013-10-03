class CreateAccessToken < ActiveRecord::Migration
  def change
    create_table :etrade_tokens do |t|
      t.string :token
      t.string :secret
      t.timestamps
    end
  end
end
