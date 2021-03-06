# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
# == Schema Information
#
# Table name: accounts
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  name            :string(64)      default(""), not null
#  website         :string(64)
#  toll_free_phone :string(32)
#  phone           :string(32)
#  fax             :string(32)
#  deleted_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  email           :string(64)
#  background_info :string(255)
#  category        :string(32)
#

class Account < ActiveRecord::Base
  include RansackableAttributes

  # This hash is used to determine whether the database contains duplicates
  # The keys are a simple title, the values either a string to match or an array to match more than one field
  DUPLICATE_FILTERS = {
    name:     [:name],
    email:    [:email],
    address:  ['addresses.address_type', 'addresses.zipcode', 'addresses.street1']
  }.freeze

  belongs_to  :user
  has_many    :account_contacts, :dependent => :destroy
  has_many    :contacts, :through => :account_contacts, :uniq => true
  has_one     :billing_address, :dependent => :destroy, :as => :addressable, :class_name => "Address", :conditions => "address_type = 'Billing'"
  has_one     :shipping_address, :dependent => :destroy, :as => :addressable, :class_name => "Address", :conditions => "address_type = 'Shipping'"
  has_many    :addresses, :dependent => :destroy, :as => :addressable, :class_name => "Address" # advanced search uses this
  has_many    :emails, :as => :mediator

  serialize :subscribed_users, Set

  accepts_nested_attributes_for :billing_address,  :allow_destroy => true, :reject_if => proc {|attributes| Address.reject_address(attributes)}
  accepts_nested_attributes_for :shipping_address, :allow_destroy => true, :reject_if => proc {|attributes| Address.reject_address(attributes)}

  scope :state, ->(filters) {
    where('category IN (?)' + (filters.delete('other') ? ' OR category IS NULL' : ''), filters)
  }
  scope :created_by,  ->(user) { where(:user_id => user.id) }

  scope :text_search, ->(query) { search('name_or_email_cont' => query).result }

  scope :visible_on_dashboard, ->(user) {
    # Show accounts which either belong to the user and are unassigned, or are assigned to the user
    where('(user_id = :user_id)', :user_id => user.id)
  }

  scope :my, lambda {
    accessible_by(User.current_ability)
  }

  scope :by_name, -> { order(:name) }

  acts_as_commentable
  uses_comment_extensions
  acts_as_taggable_on :tags
  has_paper_trail :ignore => [ :subscribed_users ]
  has_fields
  exportable
  sortable :by => [ "name ASC", "created_at DESC", "updated_at DESC" ], :default => "created_at DESC"

  has_ransackable_associations %w(contacts tags addresses comments)
  ransack_can_autocomplete

  # Exclude these attributes from Ransack search
  unransackable :user_id, :assigned_to, :website, :deleted_at, :created_at, :updated_at, :subscribed_users

  # Validate account names
  validates_presence_of :name, :message => :missing_account_name
  validates_uniqueness_of :name, :scope => :deleted_at, :if => -> { Setting.require_unique_account_names }
    
  # Validate phone numbers
  validates_format_of :phone, with: /^[\d\+\-\.\ ()]*$/, allow_blank: true
  validates_format_of :toll_free_phone, with: /^[\d\+\-\.\ ()]*$/, allow_blank: true
  validates_format_of :fax, with: /^[\d\+\-\.\ ()]*$/, allow_blank: true

  # Validate email addresses
  validates_format_of :email, with: /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i, allow_blank: true
 
  # Validate category   
  validates :category, :inclusion => { in: Proc.new{ Setting.unroll(:account_category).map{|s| s.last.to_s} } }, allow_blank: true

  before_save :nullify_blank_category

  # Default values provided through class methods.
  #----------------------------------------------------------------------------
  def self.per_page ; 20 ; end

  # Extract last line of billing address and get rid of numeric zipcode.
  #----------------------------------------------------------------------------
  def location
    return "" unless self[:billing_address]
    location = self[:billing_address].strip.split("\n").last
    location.gsub(/(^|\s+)\d+(:?\s+|$)/, " ").strip if location
  end

  # Attach given attachment to the account if it hasn't been attached already.
  #----------------------------------------------------------------------------
  def attach!(attachment)
    unless self.send("#{attachment.class.name.downcase}_ids").include?(attachment.id)
      self.send(attachment.class.name.tableize) << attachment
    end
  end

  # Discard given attachment from the account.
  #----------------------------------------------------------------------------
  def discard!(attachment)
    self.send(attachment.class.name.tableize).delete(attachment)
  end

  # Class methods.
  #----------------------------------------------------------------------------
  def self.create_or_select_for(model, params)
    if params[:id].present?
      account = Account.find(params[:id])
    else
      account = Account.new(params)
      account.save
    end
    account
  end

  # Find any duplicate records based of the given type
  #----------------------------------------------------------------------------
  def self.duplicate_search type
    return [] unless DUPLICATE_FILTERS.keys.include?(type.to_sym)

    fields = DUPLICATE_FILTERS[type.to_sym]

    # First map the fields array into a concatenated whole
    # (or just use the value if a field is a string or symbol)
    set = "CONCAT( #{fields.map{ |n| "IFNULL(#{n}, '')" }.join('," ",')} )"

    # Set the default scope to search with
    scope = self

    # If any of the fields contain references to another table, join it in
    fields.each do |field|
      if field.to_s.index('.')
        scope = scope.joins( field.to_s.split('.').first.to_sym )
      end
    end

    # Find all of this (combinations of) field(s) with more than one result
    duplicates = scope.select( "COUNT(#{set}) as `count`, #{set} as `value`" ).group( set ).having("count > 1 AND value != '' AND value IS NOT NULL")

    duplicates.order(set).map do |d|
      scope.where( "#{set} = ?", d.value )
    end
  end

  private

  def nullify_blank_category
    self.category = nil if self.category.blank?
  end

  ActiveSupport.run_load_hooks(:fat_free_crm_account, self)
end
