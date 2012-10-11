begin
  require 'spork'
rescue LoadError => e
  puts "Spork not available."
end

def configure
  # Configure Rails Environment
  ENV["RAILS_ENV"] = 'test'

  require File.expand_path('../dummy/config/environment.rb', __FILE__)

  require 'authlogic/test_case'
  include Authlogic::TestCase

  require 'rails/test_help'
  require 'rspec/rails'
  require 'factory_girl'
  require 'factories.rb'

  ActionMailer::Base.delivery_method = :test
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.default_url_options[:host] = 'test.com'

  Rails.backtrace_cleaner.remove_silencers!
  # Disable rails loggin for faster IO. Remove this if you want to have a test.log
  Rails.logger.level = 4

  # Load support files
  Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

  # Configure capybara for integration testing
  require 'capybara/rails'
  require 'capybara/poltergeist'
  Capybara.default_driver = :rack_test
  Capybara.default_selector = :css
  Capybara.javascript_driver = :poltergeist
  # Rainsing the default wait time for capybara requests
  Capybara.default_wait_time = 5

  require 'database_cleaner'
  DatabaseCleaner.strategy = :truncation

  RSpec.configure do |config|
    require 'rspec/expectations'
    config.include RSpec::Matchers
    config.include Alchemy::Engine.routes.url_helpers
    config.mock_with :rspec
    config.use_transactional_fixtures = true
  end

  DatabaseCleaner.clean!
  Alchemy::Seeder.seed!

end

if defined?(Spork)
  Spork.prefork { configure }
else
  configure
end
