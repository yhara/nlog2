source 'http://rubygems.org'

gem 'rake'

gem 'sinatra', '2.0.0.beta2'
gem 'sinatra-contrib', '2.0.0.beta2'
gem 'bcrypt'

# View
gem 'slim'
gem 'sass'
gem 'redcarpet'
gem 'builder'
gem 'rouge'

# Database 
gem 'sinatra-activerecord', git: 'https://github.com/yhara/sinatra-activerecord', branch: 'sinatra2'
gem 'sqlite3'
gem 'sequel'

# Test
group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'database_rewinder'
  gem 'timecop'
  gem 'capybara'
end

# Deploy
group :development do
  gem 'capistrano', '>= 3'
  gem 'capistrano-bundler'
  gem 'capistrano-rbenv'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
end
