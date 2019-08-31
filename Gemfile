source 'https://rubygems.org'

gem 'rake'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'bcrypt'

# View
gem 'slim'
gem 'sass'
gem 'redcarpet'
gem 'builder'
gem 'pagy'
gem 'rouge'

# Database 
gem 'activerecord'
gem 'sinatra-activerecord', github: 'greysteil/sinatra-activerecord', branch: 'support-rails-6'
gem 'sqlite3'

# Test
group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'database_rewinder'
  gem 'timecop'
  gem 'capybara'
  gem 'simplecov'
end

# Deploy
group :development do
  gem 'capistrano', '>= 3'
  gem 'capistrano-bundler'
  gem 'capistrano-rbenv'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'puma'
end
