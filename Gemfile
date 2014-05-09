source 'https://rubygems.org'

gem 'rails', '~> 3.2.0'

# Nice HTML/CSS templating
gem 'haml', '~> 3'
gem 'sass', '~> 3'

# We'll use MySQL 
gem 'mysql2'

# Jquery and a selec2 for rich select boxes
gem 'jquery-rails'
gem 'select2-rails'
gem 'responds_to_parent', '>= 1.1.0'
gem 'rails3-jquery-autocomplete'

# We use authlogic for authenticication and cancan for authorization
gem 'authlogic', '3.1.0'
gem 'cancan'

# View helpers 
gem 'simple_form', '~> 2.0.1'
gem 'will_paginate'
gem 'paperclip'
gem 'dynamic_form'

# Some behaviors for our models
gem 'acts_as_commentable', '~> 3.0.1'
gem 'acts-as-taggable-on', '~> 2.3.3'
gem 'acts_as_list', '~> 0.1.4'

# Paper trail allows us to version our data
gem 'paper_trail', '~> 2.7.0' # not ready for v3 yet

# FontAwesome webfonts prepackaged http://fortawesome.github.io/Font-Awesome/
gem 'font-awesome-rails'

# Pre-flight for HTML mail, converts css styles etc.
gem 'premailer'

# HTML/XML document parsing
gem 'nokogiri'

gem 'valium'

gem 'thor'

gem 'highline'

gem 'ffaker', '>= 1.12.0'

# We use a slightly customized ransack_ui that allows localization
gem 'ransack_ui', git: 'git@github.com:commuun/ransack_ui.git'

gem 'email_reply_parser_ffcrm'

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
