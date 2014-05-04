#
# This class makes it possible to name fields to exclude from ransack search in the model
#
# Usage:
#
#   class Blog < ActiveRecord::Base
#     # First include this module in your ransackable model:
#     include RansackableAttributes
#
#     # Then define the attribute fields to ignore:
#     unransackable :user_id, :updated_at
#   end
#
module RansackableAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    # This takes a list of attributes (strings or symbols) to exclude from Ransack search
    def unransackable *attrs
      @unransackable_attributes = attrs.map(&:to_sym)
    end

    # Note that ransack UI expects the ransackable_attributes to be in this format:
    #
    #   [[:name, :string], [:email, :string]]
    #
    # If we just return an array (Ransack default) it won't be able to show the "mask"
    # field (i.e. 'contains', 'contains_any', 'is_blank', etc.)
    #
    def ransackable_attributes auth_object = nil
      # First find the original array
      original = super(auth_object)

      # Then, if the unransackable attributes were set, remove those from the list
      if @unransackable_attributes.blank?
        original
      else
        original.reject { |a| @unransackable_attributes.include?( a.first.to_sym ) }
      end
    end
  end
end
