source 'https://rubygems.org'
gem 'rails', '4.1.8'

gem 'rails-api'
gem 'grape'
gem 'thin'

gem 'jbuilder'

gem 'capistrano'
gem 'capistrano-bundler'
gem 'capistrano-sidekiq'

gem "elasticsearch-persistence", require: 'elasticsearch/persistence/model'
gem 'instagram'
gem 'flickraw'
gem 'sidekiq'
gem 'mock_redis'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-failures'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'whenever', :require => false

gem 'newrelic_rpm'
gem "airbrake"

gem 'feedjira'

group :development, :test do
  gem 'rspec-rails', '~> 3.0.0'
end

group :test do
  gem 'rspec-sidekiq', github: 'yelled3/rspec-sidekiq', branch: 'rspec3-beta'
  gem 'simplecov', '~> 0.7.1'
  gem "codeclimate-test-reporter", require: nil
end
