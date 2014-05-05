class RemergeGroupsAndTags < ActiveRecord::Migration
  def up
    ActsAsTaggableOn::Tagging.update_all context: 'tags'
  end

  def down
    # This migration is irreversible
  end
end
