# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
# See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

class Ability
  include CanCan::Ability

  def initialize(user)

    # An alias for all basic crud operations (:manage also includes non-crud operations)
    alias_action :index, :show, :new, :create, :edit, :update, :destroy, :to => :crud

    # handle signup
    can(:create, User) if User.can_signup?

    if user.present?
      common_abilities user

      case user.role
        when 'admin'
          admin_abilities user
        when 'user'
          user_abilities user
        when 'guest'
          guest_abilities user
      end
    end
  end

  #
  # These abilities apply to all users, regardless of their role
  def common_abilities user
    # User
    can :crud, User, id: user.id # can do any action on themselves
  end

  #
  # These abilities apply to average users
  def admin_abilities user
    # Management roles also include things like finding duplicates and merging,
    # these actions are reserved for admins only
    can :manage, User
    can :manage, entities
    can :manage, Comment
  end

  #
  # These abilities apply to average users
  def user_abilities user
    can :crud, entities
    can [:read, :create], Comment
  end

  # 
  # These abilities apply to "low level" users
  def guest_abilities user
    can :read, entities
  end

  #
  # These are 'common' entities
  def entities
    [Account, Contact]
  end

  ActiveSupport.run_load_hooks(:fat_free_crm_ability, self)
end
