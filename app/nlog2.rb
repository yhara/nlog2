require 'time'
require 'sinatra/base'
require 'sinatra/reloader'
require 'bcrypt'
require 'active_support/core_ext/date'
require 'active_support/core_ext/object/to_query'
# View
require 'slim'
require 'sass'
require 'kaminari/sinatra'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
# Database
require 'sinatra/activerecord'
require_relative 'models/post.rb'
require_relative 'models/category.rb'
require_relative 'controllers/blog.rb'
require_relative 'controllers/edit.rb'
require_relative 'controllers/config.rb'

class NLog2 < Sinatra::Base
  class NotFound < StandardError; end

  def self.config; @@config or raise; end
  def self.load_config(path)
    @@config = YAML.load_file(path)
  end
  def self.logger; @@logger or raise; end
  def self.logger=(l); @@logger=l; end

  register Sinatra::ActiveRecordExtension
  configure(:development) do
    register Sinatra::Reloader
    also_reload 'app/**/*.rb'
  end

  configure do
    enable :method_override
    set :views, "#{__dir__}/views"

    enable :logging
    file = File.new("#{__dir__}/../log/#{settings.environment}.log", 'a+')
    file.sync = true
    NLog2.logger = Logger.new(file)

    use Rack::CommonLogger, NLog2.logger
    ActiveRecord::Base.logger = NLog2.logger
  end

  before do
    env["rack.logger"] = NLog2.logger

    # Seems to be needed when running on Passenger
    Time.zone = NLog2.config[:timezone]
  end

  def authenticate!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    return false unless (@auth.provided? and @auth.basic? and @auth.credentials)
    username, password = *@auth.credentials
    correct_pass = BCrypt::Password.new(NLog2.config[:auth][:password_hash])

    return (username == NLog2.config[:auth][:username]) &&
           correct_pass.is_password?(password)
  end

  error ActiveRecord::RecordNotFound do
    halt 404, 'not found'
  end

  error do
    ex = env['sinatra.error']
    logger.error("#{ex.class}: #{ex.message}")
    Array(ex.backtrace).each(&logger.method(:error))
    halt 500, 'internal server error'
  end
end
