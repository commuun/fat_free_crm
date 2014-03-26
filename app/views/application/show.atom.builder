# http://www.atomenabled.org/developers/syndication/
item   = @items.singularize

atom_feed do |feed|
  feed.title      title || t(@items.to_sym)
  feed.updated    @assets.any? ? @assets.max { |a, b| a.updated_at <=> b.updated_at }.updated_at : Time.now
  feed.generator  "Fat Free CRM v#{FatFreeCRM::VERSION::STRING}"
  feed.author do |author|
    author.name  @current_user.full_name
    author.email @current_user.email
  end

  @assets.each do |asset|
    feed.entry(asset) do |entry|
      entry.title   !asset.is_a?(User) ? asset.name : "#{asset.full_name} (#{asset.username})"
      entry.summary send(:"#{item}_summary", asset) if respond_to?(:"#{item}_summary")

      entry.author do |author|
        author.name !asset.is_a?(User) ? asset.try(:user).try(:full_name) : asset.full_name
      end

    end
  end
end
