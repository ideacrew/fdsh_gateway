# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.2'

gem 'aca_entities',  git:  'https://github.com/ideacrew/aca_entities.git', branch: 'release_0.4.0'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false
gem 'dry-matcher',          '~> 0.8'
gem 'dry-monads',           '~> 1.3'
gem 'dry-struct',           '~> 1.3'
gem 'dry-transaction',      '~> 0.13'
gem 'dry-types',            '~> 1.4'
gem 'dry-validation',       '~> 1.6'
gem 'event_source',  git:  'https://github.com/ideacrew/event_source.git', branch: 'trunk'
gem 'mongoid',             '~> 7.2.1'

# Use Puma as the app server
gem 'puma', '~> 5.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.3'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails',  '~> 6.2'
  gem 'pry-byebug', require: false
  gem 'rspec-rails',            '~> 5.0'
  gem 'shoulda-matchers',       '~> 3'
  gem 'yard'
  gem 'rubocop', '1.13.0'
  gem 'webmock'
end

group :development do
  gem 'listen', '~> 3.3'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
