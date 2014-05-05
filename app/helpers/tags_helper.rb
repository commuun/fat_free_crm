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
      query = controller.send(:current_query) || ""
      hashtag = "##{tag}"
      if query.empty?
        query = hashtag
      elsif !query.include?(hashtag)
        query += " #{hashtag}"
      end
      link = link_to_function(tag, "crm.search_tagged('#{query}', '#{model.class.to_s.tableize}')", :title => tag, :class => Setting.priority_tags.include?(tag) ? 'priority' : '' )

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

end
