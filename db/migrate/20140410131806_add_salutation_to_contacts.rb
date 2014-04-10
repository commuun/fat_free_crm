class AddSalutationToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :salutation, :string
  end
end
