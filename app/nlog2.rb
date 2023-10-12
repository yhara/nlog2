require 'time'
require 'sinatra/base'
require 'sinatra/reloader'
require 'bcrypt'
require 'active_support'
# View
require 'slim'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'pagy'
require 'pagy/extras/overflow'
# Database
require 'sinatra/activerecord'
require_relative 'models/entry.rb'
require_relative 'models/post.rb'
require_relative 'models/article.rb'
require_relative 'models/category.rb'
require_relative 'controllers/blog.rb'
require_relative 'controllers/admin.rb'
require_relative 'controllers/admin/edit.rb'
require_relative 'controllers/admin/config.rb'

class NLog2 < Sinatra::Base
  class NotFound < StandardError; end

  def self.config; @@config or raise; end
  def self.load_config(path)
    @@config = YAML.load_file(path)
  end
  def self.logger; @@logger or raise; end
  def self.logger=(l); @@logger=l; end

  register Sinatra::ActiveRecordExtension
  include Pagy::Backend

  configure(:development) do
    register Sinatra::Reloader
    also_reload "#{__dir__}/**/*.rb"
  end

  configure do
    enable :method_override
    set :views, "#{__dir__}/views"
    Pagy::DEFAULT[:overflow] = :last_page

    enable :logging
    file = File.new("#{__dir__}/../log/#{settings.environment}.log", 'a+')
    file.sync = true
    NLog2.logger = Logger.new(file)

    use Rack::CommonLogger, NLog2.logger
    ActiveRecord::Base.logger = NLog2.logger
  end

  helpers do
    include Pagy::Frontend
  end

  before do
    env["rack.logger"] = NLog2.logger

    # Seems to be needed when running on Passenger
    Time.zone = NLog2.config[:timezone]
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
