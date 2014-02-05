class AddIndexToCharityName < ActiveRecord::Migration
  def change
    add_index(:charities, :name, type: :fulltext)
  end
end
