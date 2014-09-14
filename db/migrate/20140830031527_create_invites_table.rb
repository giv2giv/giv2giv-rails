class CreateInvitesTable < ActiveRecord::Migration
  def change
    create_table :invites do |t|
    	t.integer :donor_id
      t.string :email
      t.string :hash_token
      t.boolean :accepted
      t.timestamps
    end
  end
end
