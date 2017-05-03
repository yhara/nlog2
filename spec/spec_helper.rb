ENV['RACK_ENV'] = "test"
require 'rack/test'
require 'capybara/rspec'
#require 'database_rewinder'
require 'timecop'

require_relative '../app/nlog2.rb'
require_relative '../app/post.rb'

NLog2.load_config("#{__dir__}/../config/nlog2.yml.example")
Time.zone = NLog2.config[:timezone]

RSpec.configure do |config|
  config.before(:suite) do
    #DatabaseRewinder.clean_all
  end

  config.after(:each) do
    #DatabaseRewinder.clean
  end
end
