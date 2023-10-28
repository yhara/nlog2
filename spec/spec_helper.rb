require 'simplecov'; SimpleCov.start
ENV['RACK_ENV'] = "test"
require 'rack/test'
require 'capybara/rspec'
#require 'database_rewinder'
require 'timecop'

require_relative '../app/nlog2.rb'

NLog2.load_config("#{__dir__}/../config/nlog2.yml.example")
Time.zone = NLog2.config[:timezone]

RSpec.configure do |config|
  config.before(:suite) do
    #DatabaseRewinder.clean_all
  end

  config.after(:each) do
    #DatabaseRewinder.clean
  end

  config.after(:all) do
    # Delete images created during testing
    if NLog2.config[:image_path].start_with?("public/_images/test")
      dir = "#{__dir__}/../public/_images/test"
      FileUtils.rm_r(dir) if File.directory?(dir)
    end
  end
end

class NLog2
  module IntegrationTest
    def app
      @app ||= NLog2
    end

    def login(username='jhon', password='passw0rd')
      encoded_login = ["#{username}:#{password}"].pack('m*')
      page.driver.header 'Authorization', "Basic #{encoded_login}"
    end
  end
end
