# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
class ContactsController < EntitiesController
  before_filter :get_accounts, :only => [ :new, :create, :edit, :update ]

  # GET /contacts
  #----------------------------------------------------------------------------
  def index
    @contacts = get_contacts(:page => params[:page], :per_page => params[:per_page])

    respond_with @contacts do |format|
      format.xls { render :layout => 'header' }
      format.csv { render :csv => @contacts }
    end
  end

  # GET /contacts/1
  # AJAX /contacts/1
  #----------------------------------------------------------------------------
  def show
    @comment = Comment.new
    @timeline = timeline(@contact)
    respond_with(@contact)
  end

  # GET /contacts/new
  #----------------------------------------------------------------------------
  def new
    @contact.attributes = {:user => current_user, :access => Setting.default_access}
    @account = Account.new(:user => current_user)

    if params[:related]
      model, id = params[:related].split('_')
      if related = model.classify.constantize.my.find_by_id(id)
        instance_variable_set("@#{model}", related)
      else
        respond_to_related_not_found(model) and return
      end
    end

    respond_with(@contact)
  end

  # GET /contacts/1/edit                                                   AJAX
  #----------------------------------------------------------------------------
  def edit
    @account = @contact.account || Account.new(:user => current_user)
    if params[:previous].to_s =~ /(\d+)\z/
      @previous = Contact.my.find_by_id($1) || $1.to_i
    end

    respond_with(@contact)
  end

  # POST /contacts
  #----------------------------------------------------------------------------
  def create
    @comment_body = params[:comment_body]
    respond_with(@contact) do |format|
      if @contact.save_with_account_and_permissions(params)
        @contact.add_comment_by_user(@comment_body, current_user)
        @contacts = get_contacts if called_from_index_page?
      else
        unless params[:account][:id].blank?
          @account = Account.find(params[:account][:id])
        else
          if request.referer =~ /\/accounts\/(\d+)\z/
            @account = Account.find($1) # related account
          else
            @account = Account.new(:user => current_user)
          end
        end
      end
    end
  end

  # PUT /contacts/1
  #----------------------------------------------------------------------------
  def update
    respond_with(@contact) do |format|
      unless @contact.update_with_account_and_permissions(params)
        if @contact.account
          @account = Account.find(@contact.account.id)
        else
          @account = Account.new(:user => current_user)
        end
      end
    end
  end

  # DELETE /contacts/1
  #----------------------------------------------------------------------------
  def destroy
    @contact.destroy

    respond_with(@contact) do |format|
      format.html { respond_to_destroy(:html) }
      format.js   { respond_to_destroy(:ajax) }
    end
  end

  # GET|POST /contacts/import
  #----------------------------------------------------------------------------
  def import
    if request.post?
      # If a CSV file is submitted, store it in a tempfile and allow the user to select mapping
      if params[:import][:csv_file]

        session[:temp_csv_path] = Rails.root.join( 'tmp', "#{Time.now.to_i}_#{Time.now.usec}.csv" )
        File.open( session[:temp_csv_path], 'wb' ).write( params[:import][:csv_file].read )

        # Find the headers for the imported CSV file
        @csv_header = CSV.read(session[:temp_csv_path]).first.uniq.reject(&:blank?)

      # If we've got a csv file uploaded previously, process it
      elsif !session[:temp_csv_path].blank?

        # The import method returns all lines that failed to validate (or raised an error somehow.)
        @failed_lines = Contact.import_csv File.read( session[:temp_csv_path] ), params[:import]

        # If there are contacts that failed to validate, write those lines back to a file so the
        # user can download and review them
        if @failed_lines.blank?
          session[:failed_path] = nil
        else
          # Find a new unique temporary file path where we can write the failed lines
          # For data security reasons we don't want this file in the public path
          session[:failed_path] = Rails.root.join( 'tmp', "#{Time.now.to_i}_#{Time.now.usec}.csv" )

          # Generate a CSV from the failed lines
          my_csv = CSV.generate do |csv|
            csv << @failed_lines.first.keys
            @failed_lines.each do |line|
              csv << line.values
            end
          end

          # Write those lines to the tempfile (we can download them later through the action below)
          File.open( session[:failed_path], 'w' ).write(my_csv)
        end

        # Remove the tempfile and the session reference to it
        File.unlink( session[:temp_csv_path] )
        session[:temp_csv_path] = nil
      end
    end
  end

  # GET /contacts/download_failed_import
  # Download any failed lines that were stored by the import function above.
  #----------------------------------------------------------------------------
  def download_failed_import
    if session[:failed_path].blank?
      render text: ''
    else
      send_file session[:failed_path], type: "text/csv", filename: File.basename(session[:failed_path])
    end
  end

  # PUT /contacts/1/attach
  #----------------------------------------------------------------------------
  # Handled by EntitiesController :attach

  # POST /contacts/1/discard
  #----------------------------------------------------------------------------
  # Handled by EntitiesController :discard

  # POST /contacts/auto_complete/query                                     AJAX
  #----------------------------------------------------------------------------
  # Handled by ApplicationController :auto_complete

  # GET /contacts/redraw                                                   AJAX
  #----------------------------------------------------------------------------
  def redraw
    current_user.pref[:contacts_per_page] = params[:per_page] if params[:per_page]

    # Sorting and naming only: set the same option for Leads if the hasn't been set yet.
    if params[:sort_by]
      current_user.pref[:contacts_sort_by] = Contact::sort_by_map[params[:sort_by]]
    end
    if params[:naming]
      current_user.pref[:contacts_naming] = params[:naming]
    end

    @contacts = get_contacts(:page => 1, :per_page => params[:per_page]) # Start on the first page.
    set_options # Refresh options

    respond_with(@contacts) do |format|
      format.js { render :index }
    end
  end

  private
  #----------------------------------------------------------------------------
  alias :get_contacts :get_list_of_records

  #----------------------------------------------------------------------------
  def get_accounts
    @accounts = Account.my.order('name')
  end

  def set_options
    super
    @naming = (current_user.pref[:contacts_naming]   || Contact.first_name_position) unless params[:cancel].true?
  end

  #----------------------------------------------------------------------------
  def respond_to_destroy(method)
    if method == :ajax
      if called_from_index_page?
        @contacts = get_contacts
        if @contacts.blank?
          @contacts = get_contacts(:page => current_page - 1) if current_page > 1
          render :index and return
        end
      else
        self.current_page = 1
      end
      # At this point render destroy.js
    else
      self.current_page = 1
      flash[:notice] = t(:msg_asset_deleted, @contact.full_name)
      redirect_to contacts_path
    end
  end
end
