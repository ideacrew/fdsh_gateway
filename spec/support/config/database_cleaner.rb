# frozen_string_literal: true

require 'database_cleaner-mongoid'

RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner[:mongoid].strategy = [:deletion] }
  # config.before(:suite) { DatabaseCleaner[:mongoid].clean_with(:deletion) }
  # Only delete the "users" collection.
  # DatabaseCleaner[:mongoid].strategy = :deletion, { only: ["users"] }

  # Delete all collections except the "users" collection.
  # DatabaseCleaner[:mongoid].strategy = :deletion, { except: ["users"] }
  # end

  # config.before(:each) { DatabaseCleaner[:mongoid].start }
  # config.after(:each) { DatabaseCleaner[:mongoid].clean }
  # config.after(:example, dbclean: :after_each) { DatabaseCleaner.clean }
  # config.around(:each) { |example| DatabaseCleaner.cleaning { example.run } }
end
