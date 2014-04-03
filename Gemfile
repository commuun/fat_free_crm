source 'https://rubygems.org'

# Uncomment the database that you have configured in config/database.yml
# ----------------------------------------------------------------------
# gem 'sqlite3'
gem 'mysql2'
gem 'pg'

# Disabled this hack originally from https://github.com/bundler/bundler/issues/1041
#
# The reason is that it was messing with the Gemfile.lock and as a result cap deploy failed:
#
#   You are trying to install in deployment mode after changing
#   your Gemfile. Run `bundle install` elsewhere and add the
#   updated Gemfile.lock to version control.
# 
#   You have added to the Gemfile:
#   * psych (~> 1)
#
# # Removes a gem dependency
# def remove(name)
#   @dependencies.reject! {|d| d.name == name }
# end
# 
# # Replaces an existing gem dependency (e.g. from gemspec) with an alternate source.
# def gem(name, *args)
#   remove(name)
#   super
# end
# 
# # Bundler no longer treats runtime dependencies as base dependencies.
# # The following code restores this behaviour.
# # (See https://github.com/carlhuda/bundler/issues/1041)
# spec = Bundler.load_gemspec( File.expand_path("../fat_free_crm.gemspec", __FILE__) )
# spec.runtime_dependencies.each do |dep|
#   gem dep.name, *(dep.requirement.as_list)
# end
# 
# # Remove fat_free_crm dependency, to stop it from being auto-required too early.
# remove 'fat_free_crm'

gem 'fat_free_crm'
gem 'highline'

# Remove premailer auto-require
gem 'premailer', :require => false

group :development do
  # don't load these gems in travis
  unless ENV["CI"]
    gem 'thin'
    gem 'quiet_assets'
    gem 'capistrano', '~> 2'
    gem 'capistrano_colors'
    gem 'guard'
    gem 'guard-rspec'
    gem 'guard-rails'
    gem 'rb-inotify', :require => false
    gem 'rb-fsevent', :require => false
    gem 'rb-fchange', :require => false
  end
end

group :development, :test do
  gem 'rspec-rails'
  gem 'headless'
  gem 'debugger' unless ENV["CI"]
  gem 'pry-rails' unless ENV["CI"]
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem "acts_as_fu"
  gem 'factory_girl_rails'
  gem 'zeus' unless ENV["CI"]
  gem 'coveralls', :require => false
  gem 'timecop'
end

group :heroku do
  gem 'unicorn', :platform => :ruby
  gem 'rails_12factor'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',     '>= 1.0.3'
  gem 'execjs'
  gem 'therubyracer', :platform => :ruby unless ENV["CI"]
end

gem 'turbo-sprockets-rails3'
