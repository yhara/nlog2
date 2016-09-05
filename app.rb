require 'digest'
require 'time'
require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require 'sass'
require 'sinatra/activerecord'
require 'active_support/core_ext/date'
require 'redcarpet'

class Post < ActiveRecord::Base
  validates_presence_of :body
  scope :visible, -> { where("visible = ?", true) }

  def path_to_show
    if self.published_at
      self.datetime.strftime("/%Y/%m/%d/#{slug_or_id}")
    else
      "/_draft/#{self.id}"
    end
  end
  
  def local_date
    zone = Time.find_zone!(NLog2.config[:timezone])
    self.datetime.in_time_zone(zone).to_date
  end

  def slug_or_id
    self.slug or self.id
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
  def self.config=(c); @@config = c; end

  register Sinatra::ActiveRecordExtension
  configure(:development){ register Sinatra::Reloader }

  def authenticate!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    return false unless (@auth.provided? and @auth.basic? and @auth.credentials)
    username, password = *@auth.credentials
    salt = NLog2.config[:auth][:salt] 
    hashed = Digest::SHA256.hexdigest(password + salt)

    return (username == NLog2.config[:auth][:username]) &&
           (hashed == NLog2.config[:auth][:password_hash])
  end

  error ActiveRecord::RecordNotFound do
    halt 404, 'not found'
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

  post '/_save' do
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
    begin
      @post.datetime = Time.parse(params[:datetime])
    rescue ArgumentError
      @flash_error = "Failed to parse date"
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

NLog2.config = YAML.load_file("#{__dir__}/config/nlog2.yml")
