# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module TagsHelper

  # Generate tag links for use on asset index pages.
  #----------------------------------------------------------------------------
  def tags_for_index(model)
    model.tag_list.inject([]) do |arr, tag|

      link = tag_search_link( tag, model )

      # Make sure the highlighted tags show up at the front of the list
      if Setting.priority_tags.include?(tag)
        arr.unshift( link )
      else
        arr.push( link )
      end
    end.join(" ").html_safe
  end

  def tags_for_dashboard(model)
    content_tag(:ul) do
      model.tag_list.each do |tag|
        concat(content_tag(:li, tag))
      end
    end.html_safe
  end

  def tag_search_link tag, model = nil
    query = controller.send(:current_query) || ""
    hashtag = "##{tag}"
    if query.empty?
      query = hashtag
    elsif !query.include?(hashtag)
      query += " #{hashtag}"
    end

    if model
      path_name = model.class.name.underscore.pluralize
    else
      path_name = 'contacts'
    end
    link_to tag, send( "#{path_name}_path", query: "##{tag}" ), :title => tag, :class => Setting.priority_tags.include?(tag) ? 'priority' : ''
  end

end
