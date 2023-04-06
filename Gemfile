# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.3'

gem 'aca_entities', git:  'https://github.com/ideacrew/aca_entities.git', branch: 'h36_updates'
gem 'gateway_styles', git:  'https://github.com/ideacrew/gateway-styles.git', branch: 'trunk'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

gem 'dry-matcher',          '~> 0.8'
gem 'dry-monads',           '~> 1.3'
gem 'dry-schema',           '~> 1.6'
gem 'dry-struct',           '~> 1.3'
gem 'dry-transaction',      '~> 0.13'
gem 'dry-types',            '~> 1.4'
gem 'dry-validation',       '~> 1.6'

gem 'event_source',  git:  'https://github.com/ideacrew/event_source.git', branch: 'trunk'

# Support faster redis connections
gem 'hiredis'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

gem 'money-rails', '~> 1.15'
gem 'mongoid',             '~> 7.3.1'

# Use Puma as the app server
gem 'puma', '~> 5.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.4'

# Use Redis for caching
gem 'redis', '~> 4.0'

# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'

gem 'rubyzip'

# For user accounts
gem 'devise'

# To prettify json payloads
gem 'awesome_print'
# Pagination
gem 'kaminari-mongoid'
gem 'kaminari-actionview'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'database_cleaner-mongoid'
  gem 'factory_bot_rails'
  gem 'pry-byebug', require: false
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'shoulda-matchers'
  gem 'webmock'
  gem 'yard'
end

group :development do
  gem 'listen', '~> 3.3'
  gem 'prettier'
  gem 'redcarpet'

  gem 'rubocop-git'
  gem 'rubocop-rails',          require: false
  gem 'rubocop-rake'
  gem 'rubocop-rspec'

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'

  gem 'yard-mongoid'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem 'mongoid-rspec'
  gem "selenium-webdriver"
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# gem "jsbundling-rails", "~> 1.1"
