source "http://rubygems.org"

# Declare your gem's dependencies in alchemy_contentable.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"
#gem 'alchemy_cms', :path => '/Users/mschettke/workspace/magiclabs/alchemy_cms'
gem 'alchemy_cms', '~>2.2'

group :development, :test do
  gem 'rspec-rails'
  gem 'capybara'
  gem 'sqlite3'
end

group :development do
#  gem 'ruby-debug-base19x', '~> 0.11.30.pre10'
#  gem 'ruby-debug19' #, :require => 'ruby-debug'
end

group :assets do
  gem 'therubyracer'
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end
