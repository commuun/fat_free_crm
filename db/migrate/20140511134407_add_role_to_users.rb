class AddRoleToUsers < ActiveRecord::Migration
  def up
    add_column :users, :role, :string

    User.all.each do |user|
      user.role = user.admin? ? 'admin' : 'user'
      user.save
    end

    remove_column :users, :admin
  end

  def down
    add_column :users, :admin, :boolean

    User.all.each do |user|
      user.admin = true if user.role == 'admin'
      user.save
    end

    remove_column :users, :role
  end
end
