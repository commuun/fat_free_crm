# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
# == Schema Information
#
# Table name: contacts
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  reports_to      :integer
#  first_name      :string(64)      default(""), not null
#  last_name       :string(64)      default(""), not null
#  access          :string(8)       default("Public")
#  title           :string(64)
#  department      :string(64)
#  source          :string(32)
#  email           :string(64)
#  alt_email       :string(64)
#  phone           :string(32)
#  mobile          :string(32)
#  fax             :string(32)
#  blog            :string(128)
#  linkedin        :string(128)
#  facebook        :string(128)
#  twitter         :string(128)
#  born_on         :date
#  do_not_call     :boolean         default(FALSE), not null
#  deleted_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  background_info :string(255)
#  skype           :string(128)
#

class Contact < ActiveRecord::Base
  # This hash is used to determine whether the database contains duplicates
  # The keys are a simple title, the values either a string to match or an array to match more than one field
  DUPLICATE_FILTERS = {
    email:    [:email],
    name:     [:first_name, :preposition, :last_name],
    address:  ['addresses.zipcode', 'addresses.street1']
  }.freeze

  belongs_to  :user
  belongs_to  :reporting_user, :class_name => "User", :foreign_key => :reports_to
  has_many    :account_contacts, :dependent => :destroy
  has_many    :accounts, :through => :account_contacts
  has_one     :business_address, :dependent => :destroy, :as => :addressable, :class_name => "Address", :conditions => "address_type = 'Business'"
  has_many    :addresses, :dependent => :destroy, :as => :addressable, :class_name => "Address" # advanced search uses this
  has_many    :emails, :as => :mediator

  before_save :sanitize_salutation

  has_ransackable_associations %w(account tags activities emails addresses comments)
  ransack_can_autocomplete

  serialize :subscribed_users, Set

  accepts_nested_attributes_for :account_contacts, :allow_destroy => true, :reject_if => proc {|attributes| AccountContact.reject_account_contact(attributes)}
  accepts_nested_attributes_for :business_address, :allow_destroy => true, :reject_if => proc {|attributes| Address.reject_address(attributes)}

  scope :created_by,  ->(user) { where( user_id: user.id ) }

  scope :text_search, ->(query) {
    t = Contact.arel_table
    # We can't always be sure that names are entered in the right order, so we must
    # split the query into all possible first/last name permutations.
    name_query = if query.include?(" ")
      scope, *rest = query.name_permutations.map{ |first, last|
        t[:first_name].matches("%#{first}%").and(t[:last_name].matches("%#{last}%"))
      }
      rest.map{|r| scope = scope.or(r)} if scope
      scope
    else
      t[:first_name].matches("%#{query}%").or(t[:last_name].matches("%#{query}%"))
    end

    other = t[:email].matches("%#{query}%").or(t[:alt_email].matches("%#{query}%"))
    other = other.or(t[:phone].matches("%#{query}%")).or(t[:mobile].matches("%#{query}%"))

    where( name_query.nil? ? other : name_query.or(other) )
  }

  uses_user_permissions
  acts_as_commentable
  uses_comment_extensions
  acts_as_taggable_on :tags
  has_paper_trail :ignore => [ :subscribed_users ]

  has_fields
  exportable
  sortable :by => [ "first_name ASC",  "last_name ASC", "created_at DESC", "updated_at DESC" ], :default => "created_at DESC"

  # Assign a string to this temporary value to create a new account for this contact
  attr_accessor :new_account

  before_save :add_new_account

  validates_presence_of :first_name, :message => :missing_first_name, :if => -> { Setting.require_first_names }
  validates_presence_of :last_name,  :message => :missing_last_name,  :if => -> { Setting.require_last_names  }
  validate :users_for_shared_access

  # Default values provided through class methods.
  #----------------------------------------------------------------------------
  def self.per_page ; 20                  ; end
  def self.first_name_position ; "before" ; end

  # Map all available saluations into an array for options_for_select
  #----------------------------------------------------------------------------
  def self.salutations_for_select
    Setting.salutations.map { |s|
      [I18n.t("salutations.#{s.to_sym}"), s ]
    }
  end

  #----------------------------------------------------------------------------
  def full_name(format = nil)
    if format.nil? || format == "before"
      [self.first_name, self.preposition, self.last_name]
    else
      [self.preposition, self.last_name, self.first_name]
    end.reject(&:blank?).join(' ')
  end
  alias :name :full_name

  # Backend handler for [Create New Contact] form (see contact/create).
  #----------------------------------------------------------------------------
  def save_with_account_and_permissions(params)
    result = self.save
    result
  end

  # Backend handler for [Update Contact] form (see contact/update).
  #----------------------------------------------------------------------------
  def update_with_account_and_permissions(params)
    # Must set access before user_ids, because user_ids= method depends on access value.
    self.access = params[:contact][:access] if params[:contact][:access]
    self.attributes = params[:contact]
    self.save
  end

  # Attach given attachment to the contact if it hasn't been attached already.
  #----------------------------------------------------------------------------
  def attach!(attachment)
    unless self.send("#{attachment.class.name.downcase}_ids").include?(attachment.id)
      self.send(attachment.class.name.tableize) << attachment
    end
  end

  # Discard given attachment from the contact.
  #----------------------------------------------------------------------------
  def discard!(attachment)
    self.send(attachment.class.name.tableize).delete(attachment)
  end

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
  # Make sure at least one user has been selected if the contact is being shared.
  #----------------------------------------------------------------------------
  def users_for_shared_access
    errors.add(:access, :share_contact) if self[:access] == "Shared" && !self.permissions.any?
  end

  # Handles importing and processing new contact data
  # > Takes a string containing the CSV data and a hash which maps the column
  #   names of the CSV file to the database fields, e.g. { first_name: 'givenname' }
  # > Returns an array of contacts that failed to validate or raised an error
  #----------------------------------------------------------------------------
  def self.import_csv( data, mapping )
    failed_lines = []

    CSV.parse( data, headers: true, col_sep: Setting.csv_separator ) do |line|

      begin
        contact = Contact.new
        mapping[:contact].each do |field, mapping|
          # We need to use send here or tag_list won't work
          contact.send( "#{field}=", line[mapping] )
        end

        address = contact.addresses.new
        address.address_type = 'Business'
        mapping[:contact_address].each do |field, mapping|
          address[field] = line[mapping]
        end

        Rails.logger.debug ">> Saving contact: #{contact.inspect} with addresses: #{contact.addresses.inspect} (#{address.valid?})"
        if contact.save
          account = Account.where( name: line[mapping[:account][:name]] ).first_or_initialize
          mapping[:account].each do |field, mapping|
            account[field] = line[mapping]
          end
          b_address = account.billing_address || account.addresses.new( address_type: 'Billing' )
          s_address = account.shipping_address || account.addresses.new( address_type: 'Shipping' )
          mapping[:account_address].each do |field, mapping|
            b_address[field] = line[mapping]
            s_address[field] = line[mapping]
          end
          Rails.logger.debug ">> Saving account: #{account.inspect} with addresses: #{account.addresses.inspect}"
          if account.save
            account.contacts << contact
          end
        else
          failed_lines << line.to_hash.merge(error: contact.errors.full_messages.join(', '))
        end

      rescue Exception => e
        # If an exception occurred, add it to the error report
        contact.errors.add( :base, "#{e.class.name}: #{e.message}" )
        failed_lines << line.to_hash.merge(error: "#{e.class.name}: #{e.message}")

        Rails.logger.info "An error occurred importing csv line:"
        Rails.logger.info "#{e.class.name}: #{e.message}"
        Rails.logger.info e.backtrace.join("\n")
      end
    end

    failed_lines
  end

  def self.import_attributes
    {
      account: [:name, :email, :website, :phone, :fax],
      contact: [:first_name, :last_name, :preposition, :salutation, :title, :department, :email, :phone, :mobile, :fax, :tag_list],
      address: [:street1, :street2, :city, :zipcode, :country]
    }
  end

  def add_new_account
    unless self.new_account.blank?
      self.accounts.build name: self.new_account
    end
  end

  # Make sure the salutation given for this contact is in the list or in the locale
  def sanitize_salutation
    unless Setting.salutations.include?( self.salutation.to_sym )
      self.salutation = I18n.t('salutations').invert[self.salutation]
    end
  end

  ActiveSupport.run_load_hooks(:fat_free_crm_contact, self)
end
