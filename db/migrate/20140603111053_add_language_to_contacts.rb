class AddLanguageToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :language, :string
  end
end
