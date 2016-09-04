ENV['RACK_ENV'] = "test"
require 'rack/test'
#require 'database_rewinder'
require 'timecop'

require_relative '../app.rb'

NLog2.config = YAML.load_file("#{__dir__}/../config/nlog2.yml.example")

RSpec.configure do |config|
  config.before(:suite) do
    #DatabaseRewinder.clean_all
  end

  config.after(:each) do
    #DatabaseRewinder.clean
  end
end
