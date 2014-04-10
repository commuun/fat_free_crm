class AddPrepositionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :preposition, :string
  end
end
