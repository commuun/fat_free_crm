class TagsController < ApplicationController
  before_filter :require_user

  def index
    @tags = Tag.joins(:taggings).select('name, count(taggings.id) as cnt').group('tags.id, name').having( 'name like ?', "%#{params[:term]}%" ).order('cnt desc')

    render json: @tags.map { |t| [ t.name, "#{t.name} (#{t.cnt})" ] }
  end

end
