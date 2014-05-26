class TagsController < ApplicationController
  before_filter :require_user

  def index
    @tags = { priority: [], tags: [] }

    respond_to do |format|
      format.html
      format.js do
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

  def merge
    @tag = Tag.find( params[:id] )
    @merge = Tag.find( params[:merge_id] )
  end

end
