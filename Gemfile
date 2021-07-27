# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# ruby '2.7.2'

gem 'aca_entities',  git:  'https://github.com/ideacrew/aca_entities.git', branch: 'release_0.3.0'

# This gem overrides Rails' UJS behaviour to open up a Bootstrap Modal instead of the browser's built in confirm() dialog
gem 'data-confirm-modal'

gem 'dry-matcher',          '~> 0.8'
gem 'dry-monads',           '~> 1.3'
gem 'dry-struct',           '~> 1.3'
gem 'dry-transaction',      '~> 0.13'
gem 'dry-types',            '~> 1.4'
gem 'dry-validation',       '~> 1.6'
gem 'event_source',  git:  'https://github.com/ideacrew/event_source.git', branch: 'release_0.5.3'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# jQuery UI's JavaScript, CSS, and image files packaged for the Rails 3.1+ asset pipeline
gem 'jquery-ui-rails'

# SSO Authentication
gem 'keycloak', '~> 3.2', '>= 3.2.1'

gem 'mongoid',             '~> 7.2.1'

# Rack middleware to enable Keycloak authentication
# gem 'omniauth-keycloak'

# Use Puma as the app server
gem 'puma', '~> 5.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.3', '>= 6.1.3.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails'
  gem 'pry-byebug', require: false
  gem 'rspec-rails',            '~> 5.0'
  gem 'shoulda-matchers',       '~> 3'
  gem 'yard'
  gem 'rubocop', '1.10.0'
  gem 'webmock'
end

group :development do
  gem 'listen', '~> 3.3'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
