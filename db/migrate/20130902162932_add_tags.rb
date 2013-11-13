class AddTags < ActiveRecord::Migration
  def change
    create_table(:tags, options: 'ENGINE = MyISAM') do |t|
      t.integer :id, :null => false
      t.text :name
      t.timestamps
    end

    create_table :charities_tags, :id => false do |t|
      t.references :charity, :null => false
      t.references :tag, :null => false
    end

    add_index(:tags, :name, type: :fulltext)
    add_index(:charities_tags, [:charity_id, :tag_id], :unique => true)
    add_index :tags, :id
  end
end
