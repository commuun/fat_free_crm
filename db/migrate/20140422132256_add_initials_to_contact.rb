class AddInitialsToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :initials, :string
  end
end
