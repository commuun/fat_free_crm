class AddBackgroundInfoToModels < ActiveRecord::Migration
  def self.up
    add_column :accounts, :background_info, :string
    add_column :contacts, :background_info, :string
  end

  def self.down
    remove_column :accounts, :background_info
    remove_column :contacts, :background_info
  end
end

