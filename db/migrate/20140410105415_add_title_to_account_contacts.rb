class AddTitleToAccountContacts < ActiveRecord::Migration
  def change
    add_column :account_contacts, :title, :string
    add_column :account_contacts, :department, :string
  end
end
