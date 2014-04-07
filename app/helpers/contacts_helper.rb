# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module ContactsHelper
  # Contact summary for RSS/ATOM feeds.
  #----------------------------------------------------------------------------
  def contact_summary(contact)
    summary = [""]
    summary << contact.title.titleize if contact.title?
    summary << contact.department if contact.department?
    if contact.account && contact.account.name?
      summary.last << " #{t(:at)} #{contact.account.name}"
    end
    summary << contact.email if contact.email.present?
    summary << "#{t(:phone_small)}: #{contact.phone}" if contact.phone.present?
    summary << "#{t(:mobile_small)}: #{contact.mobile}" if contact.mobile.present?
    summary.join(', ')
  end

  def import_contacts_link
    link_to import_contacts_path, :text => t('import_contacts') do
      content_tag( :span, '&#9658;'.html_safe, class: 'arrow' ) + t('import_contacts')
    end
  end

  def find_duplicates_contacts_link
    link_to find_duplicates_contacts_path, :text => t('duplicate_contacts') do
      content_tag( :span, '&#9658;'.html_safe, class: 'arrow' ) + t('duplicate_contacts')
    end
  end

  def duplicate_filter_options
    Contact::DUPLICATE_FILTERS.keys.map do |filter|
      if filter == @filter
        content_tag( :strong, t(filter) )
      else
        link_to t(filter), find_duplicates_contacts_path( filter: filter )
      end
    end.join(' | ').html_safe
  end

  def contact_account_links contact
    contact.accounts.map do |account|
      link_to account.name, account
    end.join(', ').html_safe
  end

end
