# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AccountsHelper

  # Sidebar checkbox control for filtering accounts by category.
  #----------------------------------------------------------------------------
  def account_category_checkbox(category, count)
    entity_filter_checkbox(:category, category, count)
  end

  # Quick account summary for RSS/ATOM feeds.
  #----------------------------------------------------------------------------
  def account_summary(account)
    [
      t(:added_by, :time_ago => time_ago_in_words(account.created_at), :user => account.user_id_full_name),
      t('pluralize.contact', account.contacts.count),
      t('pluralize.comment', account.comments.count)
    ].join(', ')
  end

  # Link to the "find duplicates" view
  #----------------------------------------------------------------------------
  def find_duplicates_accounts_link
    link_to find_duplicates_accounts_path, :text => t('duplicate_accounts') do
      content_tag( :span, '&#9658;'.html_safe, class: 'arrow' ) + t('duplicate_accounts')
    end
  end

  # Generates a select list with the first 25 accounts
  # and prepends the currently selected account, if any.
  #----------------------------------------------------------------------------
  def account_select(options = {})
      options[:selected] = (@account && @account.id) || 0
      accounts = ([@account] + Account.my.order(:name).limit(25)).compact.uniq
      collection_select :account, :id, accounts, :id, :name, options,
                        {:"data-placeholder" => t(:select_an_account),
                         :"data-url" => auto_complete_accounts_path(format: 'json'),
                         :style => "width:330px; display:none;",
                         :class => 'ajax_chosen' }
  end

  # Select an existing account or create a new one.
  #----------------------------------------------------------------------------
  def account_select_or_create(form, &block)
    options = {}
    yield options if block_given?

    content_tag(:div, :class => 'label') do
      t(:account).html_safe +

      content_tag(:span, :id => 'account_create_title') do
        "(#{t :create_new} #{t :or} <a href='#' onclick='crm.select_account(); return false;'>#{t :select_existing}</a>):".html_safe
      end.html_safe +

      content_tag(:span, :id => 'account_select_title') do
        "(<a href='#' onclick='crm.create_account(); return false;'>#{t :create_new}</a> #{t :or} #{t :select_existing}):".html_safe
      end.html_safe +

      content_tag(:span, ':', :id => 'account_disabled_title').html_safe
    end.html_safe +

    account_select(options).html_safe +
    form.text_field(:name, :style => 'width:324px; display:none;')
  end

  # Output account url for a given contact
  # - a helper so it is easy to override in plugins that allow for several accounts
  #----------------------------------------------------------------------------
  def account_with_url_for(contact)
    accounts = []
    contact.accounts.each do |account|
      accounts << link_to(h(account.name), account_path(account))
    end
    accounts.join(', ').html_safe
  end

  # Output account with title and department
  # - a helper so it is easy to override in plugins that allow for several accounts
  #----------------------------------------------------------------------------
  def account_with_title_and_department(contact)
    text = if !contact.title.blank? && !contact.accounts.blank?
        contact.account_contacts.map do |account_contact|
          t(:works_at, :job_title => h(account_contact.title), :company => link_to( account_contact.account.name, account_contact.account) ).html_safe
        end.join(', ').html_safe
      elsif !contact.title.blank?
        content_tag :div, h(contact.title)
      elsif !contact.accounts.empty?
        content_tag :div, account_with_url_for(contact)
      else
        ""
      end
    text << t(:department_small, h(contact.department)) unless contact.department.blank?
    text
  end

  # "title, department at Account name" used in index_brief and index_long
  # - a helper so it is easy to override in plugins that allow for several accounts
  #----------------------------------------------------------------------------
  def brief_account_info(contact)
    text = []

    contact.account_contacts.each do |account_contact|
      account = account_contact.account
      title = account_contact.title
      department = account_contact.department

      account_text = account.present? ? link_to_if(can?(:read, account), h(account.name), account_path(account)) : ''

      text << if title.present? && department.present?
            t(:account_with_title_department, :title => h(title), :department => h(department), :account => account_text)
          elsif title.present?
            t(:account_with_title, :title => h(title), :account => account_text)
          elsif department.present?
            t(:account_with_title, :title => h(department), :account => account_text)
          elsif account_text.present?
            t(:works_at, :job_title => "", :company => account_text)
          else
            ""
          end
    end
    text.join(', ').html_safe
  end

end
