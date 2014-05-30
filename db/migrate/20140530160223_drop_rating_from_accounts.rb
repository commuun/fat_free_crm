class DropRatingFromAccounts < ActiveRecord::Migration
  def up
    remove_column :accounts, :rating
  end

  def down
    add_column :accounts, :rating, :integer, :default => 0
  end
end
