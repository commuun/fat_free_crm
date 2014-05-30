# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
class AccountsController < EntitiesController
  before_filter :get_data_for_sidebar, :only => :index

  # GET /accounts
  #----------------------------------------------------------------------------
  def index
    @accounts = get_accounts(:page => params[:page], :per_page => params[:per_page])

    respond_with @accounts do |format|
      format.xls {
        add_comment( @accounts, params[:comment] )
        render :layout => 'header'
      }
      format.csv {
        add_comment( @accounts, params[:comment] )
        render :csv => @accounts
      }
    end
  end

  # GET /accounts/1
  # AJAX /accounts/1
  #----------------------------------------------------------------------------
  def show
    @comment = Comment.new
    @timeline = timeline(@account)
    respond_with(@account)
  end

  # GET /accounts/new
  #----------------------------------------------------------------------------
  def new
    @account.attributes = {:user => current_user}

    if params[:related]
      model, id = params[:related].split('_')
      instance_variable_set("@#{model}", model.classify.constantize.find(id))
    end

    respond_with(@account)
  end

  # GET /accounts/1/edit                                                   AJAX
  #----------------------------------------------------------------------------
  def edit
    if params[:previous].to_s =~ /(\d+)\z/
      @previous = Account.my.find_by_id($1) || $1.to_i
    end

    respond_with(@account)
  end

  # POST /accounts
  #----------------------------------------------------------------------------
  def create
    @comment_body = params[:comment_body]
    respond_with(@account) do |format|
      if @account.save
        @account.add_comment_by_user(@comment_body, current_user)
        # None: account can only be created from the Accounts index page, so we
        # don't have to check whether we're on the index page.
        @accounts = get_accounts
        get_data_for_sidebar
      end
    end
  end

  # PUT /accounts/1
  #----------------------------------------------------------------------------
  def update
    respond_with(@account) do |format|
      get_data_for_sidebar if @account.update_attributes(params[:account])
    end
  end

  # DELETE /accounts/1
  #----------------------------------------------------------------------------
  def destroy
    @account.destroy

    respond_with(@account) do |format|
      format.html { respond_to_destroy(:html) }
      format.js   { respond_to_destroy(:ajax) }
    end
  end

  # PUT /accounts/1/attach
  #----------------------------------------------------------------------------
  # Handled by EntitiesController :attach

  # POST /accounts/auto_complete/query                                     AJAX
  #----------------------------------------------------------------------------
  # Handled by ApplicationController :auto_complete

  # GET /accounts/redraw                                                   AJAX
  #----------------------------------------------------------------------------
  def redraw
    current_user.pref[:accounts_per_page] = params[:per_page] if params[:per_page]
    current_user.pref[:accounts_sort_by]  = Account::sort_by_map[params[:sort_by]] if params[:sort_by]
    @accounts = get_accounts(:page => 1, :per_page => params[:per_page])
    set_options # Refresh options

    respond_with(@accounts) do |format|
      format.js { render :index }
    end
  end

  # POST /accounts/filter                                                  AJAX
  #----------------------------------------------------------------------------
  def filter
    session[:accounts_filter] = params[:category]
    @accounts = get_accounts(:page => 1, :per_page => params[:per_page])

    respond_with(@accounts) do |format|
      format.js { render :index }
    end
  end


  # GET /accounts/find_duplicates
  #----------------------------------------------------------------------------
  def find_duplicates
    @filter = (params[:filter] || Account::DUPLICATE_FILTERS.keys.first).to_sym
    @duplicates = Account.duplicate_search( @filter )
  end


  # MATCH /accounts/merge
  #----------------------------------------------------------------------------
  def merge
    # Find all accounts to merge
    @accounts = Account.find( params[:accounts] )

    # If POST then the form was submitted
    if request.put? || request.post?
      # Take the first account as a base
      @account = @accounts.shift

      Account.transaction do

        # For some reason, assigning an address through nested attributes when
        # the address is nil the address_type does not get set properly unless
        # we assign it manually here.
        params[:account][:billing_address_attributes][:address_type] = 'Billing'
        params[:account][:shipping_address_attributes][:address_type] = 'Shipping'

        # And apply the submitted parameters to it
        @account.assign_attributes(params[:account])
        if @account.save(validate: false)
          # If successful, destroy all the other mergable accounts
          @accounts.each(&:destroy)
          # And show the new account
          redirect_to @account
        end
      end
    else
      # Take the first account as the base record
      @account = @accounts.first

      # Apply the tags and groups from the other accounts to the base
      @account.tag_list = @accounts.map{ |c| c.tag_list }.flatten.uniq

      # If any of the fields in the base account is blank, fill it in with one of the others
      %w[name category toll_free_phone phone fax website email].each do |attribute|
        idx = 0
        while @account[attribute].blank? && idx < @accounts.count
          @account[attribute] = @accounts[idx][attribute]
          idx += 1
        end
      end
      @account.build_billing_address if @account.billing_address.blank?
      @account.build_shipping_address if @account.shipping_address.blank?
    end
  end

private

  #----------------------------------------------------------------------------
  alias :get_accounts :get_list_of_records

  #----------------------------------------------------------------------------
  def respond_to_destroy(method)
    if method == :ajax
      @accounts = get_accounts
      get_data_for_sidebar
      if @accounts.empty?
        @accounts = get_accounts(:page => current_page - 1) if current_page > 1
        render :index and return
      end
      # At this point render default destroy.js
    else # :html request
      self.current_page = 1 # Reset current page to 1 to make sure it stays valid.
      flash[:notice] = t(:msg_asset_deleted, @account.name)
      redirect_to accounts_path
    end
  end

  #----------------------------------------------------------------------------
  def get_data_for_sidebar
    @account_category_total = Hash[
      Setting.account_category.map do |key|
        [ key, Account.my.where(:category => key.to_s).count ]
      end
    ]
    categorized = @account_category_total.values.sum
    @account_category_total[:all] = Account.my.count
    @account_category_total[:other] = @account_category_total[:all] - categorized
  end
end
