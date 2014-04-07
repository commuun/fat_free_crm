class AddPrepositionToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :preposition, :string
  end
end
