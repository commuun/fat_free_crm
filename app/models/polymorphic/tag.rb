# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
class Tag < ActsAsTaggableOn::Tag
  before_destroy :no_associated_field_groups

  has_many :taggings

  scope :with_context, lambda { |context| includes(:taggings).where( 'taggings.context = ?', context ) }

  scope :order_by_taggings, lambda { joins(:taggings).select('tags.id as id, tags.name as name, count(taggings.id) as cnt').group('name').order('cnt desc') }

  scope :priority, lambda { where(name: Setting.priority_tags) } 
  scope :non_priority, lambda { where('name not in (?)', Setting.priority_tags) } 

  # If this accessor is set with the name of another tag, all taggings belonging to the current tag will be
  # moved to the "merge_with" tag and the current tag will be destroyed.
  attr_accessor :merge_with
  attr_accessible :merge_with

  after_save :merge

  # Don't allow a tag to be deleted if it is associated with a Field Group
  def no_associated_field_groups
    FieldGroup.find_all_by_tag_id(self).none?
  end

  # Returns a count of taggings per model klass
  # e.g. {"Contact" => 3, "Account" => 1}
  def model_tagging_counts
    Tagging.where(:tag_id => id).count(:group => :taggable_type)
  end

  def merge
    if @merge_with && merge_tag = Tag.where( name: @merge_with ).where( 'tags.id != ?', self.id ).first
      self.taggings.update_all :tag_id => merge_tag.id
      self.destroy
    end
  end

end
