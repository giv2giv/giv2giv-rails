class AddTags < ActiveRecord::Migration


  def self.up
    execute 'ALTER TABLE tags ENGINE = MyISAM'
    execute 'CREATE FULLTEXT INDEX fulltext_tags ON tags(name)'
  end

  def self.down
    execute 'ALTER TABLE tags ENGINE = InnoDB'
    execute 'DROP INDEX fulltext_tags ON tags'
  end

  def change
    create_table :tags do |t|
      t.integer :id, :null => false
      t.text :name
      t.timestamps
    end

    create_table :charities_tags, :id => false do |t|
      t.references :charity, :null => false
      t.references :tag, :null => false
    end

    add_index(:charities_tags, [:charity_id, :tag_id], :unique => true)
    add_index :tags, :id
  end
end
