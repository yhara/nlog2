require 'time'
require 'sinatra/base'
require 'sinatra/reloader'
require 'bcrypt'
require 'slim'
require 'sass'
require 'sinatra/activerecord'
require 'active_support/core_ext/date'
require 'redcarpet'

class Post < ActiveRecord::Base
  validates_presence_of :body
  validates_presence_of :datetime
  scope :visible, -> { where("visible = ?", true).order(datetime: :desc) }

  def url
    URI.join(NLog2.config[:blog][:url], path_to_show).to_s
  end

  def path_to_show
    if self.published_at
      self.datetime.strftime("/%Y/%m/%d/#{slug_or_id}")
    else
      "/_draft/#{self.id}"
    end
  end

  def path_to_edit
    "/_edit/#{self.id}"
  end
  
  def local_date
    local_datetime.to_date
  end

  def local_datetime
    self.datetime.in_time_zone(Time.zone)
  end

  def slug_or_id
    return slug if slug && !slug.empty?
    return self.id.to_s
  end

  def rendered_body
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      footnotes: true,
    )
    markdown.render(self.body)
  end
end

class NLog2 < Sinatra::Base
  class NotFound < StandardError; end

  def self.config; @@config or raise; end
  def self.load_config(path)
    @@config = YAML.load_file(path)
  end
  def self.logger; @@logger or raise; end
  def self.logger=(l); @@logger=l; end

  register Sinatra::ActiveRecordExtension
  configure(:development){ register Sinatra::Reloader }

  configure do
    enable :logging
    file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
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

  #
  # Show
  #

  get %r{(\d\d\d\d)/(\d\d)/(\d\d)/(.+)} do
    *date, slug_or_id = *params[:captures]
    d = Date.new(*date.map(&:to_i))
    range = d.to_time(:utc)...(d+1).to_time(:utc)

    cond = Post.where(slug: slug_or_id)
    if (id = Integer(slug_or_id) rescue nil)
      cond = cond.or(Post.where(id: id))
    end

    @post = cond.where(datetime: range, visible: true).first!

    slim :show
  end

  get '/_draft/:id' do
    authenticate!
    @post = Post.unscoped.find_by!(id: params[:id], published: false)
    slim :show
  end

  get '/' do
    @posts = Post.order(datetime: :desc)
    slim :index  # renders views/index.slim
  end

  get '/screen.css' do
    sass :screen  # renders views/screen.sass as screen.css
  end

  get '/_feed.xml' do
    @feed_posts = Post.visible.limit(10)
    builder :_feed
  end

  #
  # Edit
  #
  
  get '/_edit' do redirect '/_edit/' end
  get '/_edit/:id?' do
    authenticate!
    if (id = params[:id])
      @post = Post.find_by!(id: id)
    else
      @post = Post.new
      @post.datetime = Time.now
    end
    slim :edit
  end

  post '/_edit' do
    authenticate!
    @flash_error = nil
    if (id = params[:id])
      @post = Post.find_by!(id: id)
    else
      @post = Post.new
    end

    @post.title = params[:title]
    @post.slug = params[:slug]
    @post.body = params[:body]
    @post.visible = (params[:visible] == "y")
    if (d = Time.zone.parse(params[:datetime]) rescue nil)
      @post.datetime = d
    else
      @flash_error = "Failed to parse date: #{params[:datetime].inspect}"
      @post.datetime = Time.now
    end

    if params[:submit_by] == "Save" && !@flash_error
      @post.published_at ||= Time.now if @post.visible
      @post.save!
      redirect @post.path_to_show
    else
      slim :edit
    end
  end
end

NLog2.load_config("#{__dir__}/config/nlog2.yml")
