require 'digest'
require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require 'sass'
require "sinatra/activerecord"

class Post < ActiveRecord::Base
  validates_presence_of :body
  scope :visible, -> { where("visible = ?", true) }

  def path_to_show
    if self.published_at
      self.published_at.strftime("/%Y/%m/%d/#{slug_or_id}")
    else
      "/_draft/#{self.id}"
    end
  end

  def slug_or_id
    self.slug or self.id
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

  get '/(\d\d\d\d)/(\d\d)/(\d\d)/:slug' do
    date = Date.new(*params[:captures])
    @post = Post.find_by!(posted_on: date, published: true)
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
    end
    slim :edit
  end

  post '/_save' do
    authenticate!
    if (id = params[:id])
      @post = Post.find_by!(id: id)
    else
      @post = Post.new
    end
    @post.title = params[:title]
    @post.slug = params[:slug]
    @post.body = params[:body]
    @post.visible = (params[:visible] == "y")

    if params[:submit_by] == "Save"
      @post.published_at ||= Time.now if @post.visible
      @post.save!
      redirect @post.path_to_show
    else
      slim :edit
    end
  end
end

NLog2.config = YAML.load_file("#{__dir__}/config/nlog2.yml")
