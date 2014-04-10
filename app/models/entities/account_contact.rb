# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
# == Schema Information
#
# Table name: account_contacts
#
#  id         :integer         not null, primary key
#  account_id :integer
#  contact_id :integer
#  deleted_at :datetime
#  created_at :datetime
#  updated_at :datetime
#

class AccountContact < ActiveRecord::Base
  belongs_to :account
  belongs_to :contact

  has_paper_trail :meta => { :related => :contact }, :ignore => [ :id, :created_at, :updated_at, :contact_id ]

  validates_presence_of :account_id

  ActiveSupport.run_load_hooks(:fat_free_crm_account_contact, self)

  #----------------------------------------------------------------------------
  # Ensure blank address records don't get created. If we have a new record and
  #   address is empty then return true otherwise return false so that _destroy
  #   is processed (if applicable) and the record is removed.
  # Intended to be called as follows:
  #   accepts_nested_attributes_for :business_address, :allow_destroy => true, :reject_if => proc {|attributes| Address.reject_address(attributes)}
  def self.reject_account_contact(attributes)
    exists = attributes['id'].present?
    empty = %w(account_id contact_id).map{|name| attributes[name].blank?}.all?
    attributes.merge!({:_destroy => 1}) if exists and empty
    return (!exists and empty)
  end

end
