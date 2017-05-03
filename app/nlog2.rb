require 'time'
require 'logger'
require 'sinatra/base'
require 'sinatra/reloader'
require 'bcrypt'
require 'active_support/core_ext/date'
require 'active_support/core_ext/object/to_query'
# View
require 'slim'
require 'sass'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

class NLog2 < Sinatra::Base
  class NotFound < StandardError; end

  def self.config; @@config or raise; end
  # Set config and connect to the database
  def self.init(config_path)
    @@config = YAML.load_file(config_path)
    require_relative 'models/post.rb'
  end
  def self.logger; @@logger or raise; end
  def self.logger=(l); @@logger=l; end

  configure(:development){ register Sinatra::Reloader }

  configure do
    enable :logging
    file = File.new("#{__dir__}/../log/#{settings.environment}.log", 'a+')
    file.sync = true
    NLog2.logger = Logger.new(file)

    use Rack::CommonLogger, NLog2.logger
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

  #
  # View Helpers
  #

  helpers do
    def previous_page_path(scope, params={})
      return nil if scope.first_page?
      query = params.merge(page: scope.prev_page)
      return env['PATH_INFO'] + (query.empty? ? '' : "?#{query.to_query}")
    end

    def next_page_path(scope, params={})
      return nil if scope.last_page?
      query = params.merge(page: scope.next_page)
      return env['PATH_INFO'] + (query.empty? ? '' : "?#{query.to_query}")
    end
  end

  #
  # Show
  #

  get '/' do
    @posts = Post.published
                 .where(permanent: false)
                 .order(Sequel.desc(:datetime)).paginate(params[:page] || 1, 10)
    slim :index
  end

  get '/_list' do
    @posts = Post.published
                 .where(permanent: false)
                 .order(Sequel.desc(:datetime)).paginage(params[:page] || 1, 100)
    @articles = Post.published
                    .where(permanent: true)
                    .order(Sequel.desc(:updated_at))
    slim :list
  end

  get %r{/(\d\d\d\d)/(\d\d)/(\d\d)/(.+)} do
    *date, slug_or_id = *params[:captures]
    d = Date.new(*date.map(&:to_i))
    range = d.in_time_zone...(d+1).in_time_zone

    cond = Post.published.where(permanent: false, slug: slug_or_id)
    if (id = Integer(slug_or_id) rescue nil)
      cond = cond.or(Post.where(id: id))
    end

    @post = cond.where(datetime: range).first or raise Sinatra::NotFound
    @title = @post.title
    slim :show
  end

  get '/screen.css' do
    sass :screen  # renders views/screen.sass as screen.css
  end

  get '/highlight.css' do
    headers 'Content-Type' => 'text/css'
    Rouge::Themes::Github.render(scope: '.highlight')
  end

  get '/_feed.xml' do
    @feed_posts = Post.published
                      .where(permanent: false)
                      .order(Sequel.desc(:datetime)).limit(10)
    builder :_feed
  end

  #
  # Edit
  #
  
  get '/_edit' do redirect '/_edit/' end
  get '/_edit/:id?' do
    authenticate!
    @flash = {}
    if (id = params[:id])
      @post = Post.find_by(id: id) or raise Sinatra::NotFound
    else
      @post = Post.new
      @post.datetime = Time.now
    end
    @title = "Edit"
    slim :edit
  end

  post '/_edit' do
    authenticate!
    @flash = {}
    if (id = params[:id])
      @post = Post.find_by(id: id) or raise Sinatra::NotFound
    else
      @post = Post.new
    end

    @post.permanent = (params[:permanent] == "yes")
    @post.title = params[:title]
    @post.slug = params[:slug]
    @post.body = params[:body]
    if (d = Time.zone.parse(params[:datetime]) rescue nil)
      @post.datetime = d
    else
      @flash[:error] = "Failed to parse date: #{params[:datetime].inspect}"
      @post.datetime = Time.now
    end

    if params[:submit_by] == "Save" && !@flash[:error]
      @post.published_at ||= Time.now
      if @post.save
        if @post.future?
          @flash[:notice] = "Scheduled `#{@post.title}' to be posted at #{@post.author_datetime}"
          @post = Post.new; @post.datetime = Time.now
          slim :edit
        else
          redirect @post.path_to_show
        end
      else
        @flash[:error] = "Failed to save record: #{@post.errors.messages.inspect}"
        slim :edit
      end
    else
      # Opt-out XSS Protection for this response, because it may contain
      # <script> tag (eg. embedding SpeakerDeck) which the user has written.
      headers "X-XSS-Protection" => "0" 
      @title = "Edit"
      slim :edit
    end
  end

  #
  # Permanent articles
  #
  get %r{/(\w+)} do |name|
    @post = Post.published.where(permanent: true, slug: name).first
    raise Sinatra::NotFound unless @post
    @title = @post.title
    slim :show
  end
end
