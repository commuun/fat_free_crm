class TagsController < ApplicationController
  before_filter :require_user

  def index
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
