class TagsController < ApplicationController
  before_filter :require_user

  load_and_authorize_resource

  def index

    respond_to do |format|
      format.html
      format.js do
        @tags = { priority: [], tags: [] }

        Tag.joins(:taggings).select('name, count(taggings.id) as cnt').group('tags.id, name').having( 'name like ?', "%#{params[:term]}%" ).order('cnt desc').each do |tag|
          if Setting.priority_tags.include?( tag.name )
            @tags[:priority] << tag
          else
            @tags[:tags] << tag
          end
        end
        render json: {
          tags: @tags[:tags].map { |t| [ t.name, "#{t.name} (#{t.cnt})" ] },
          priority: @tags[:priority].map { |t| [ t.name, "#{t.name} (#{t.cnt})" ] }
        }
      end
    end
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new params[:tag]
    if @tag.save
      redirect_to tags_path
    else
      render 'new'
    end
  end

  def edit
    @tag = Tag.find( params[:id] )
  end

  def update
    @tag = Tag.find( params[:id] )
    if @tag.update_attributes params[:tag]
      redirect_to tags_path
    else
      render 'edit'
    end
  end

end
