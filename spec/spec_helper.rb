ENV['RACK_ENV'] = "test"
require 'rack/test'
#require 'database_rewinder'
require 'timecop'

require_relative '../app.rb'

RSpec.configure do |config|
  config.before(:suite) do
    #DatabaseRewinder.clean_all
  end

  config.after(:each) do
    #DatabaseRewinder.clean
  end
end
