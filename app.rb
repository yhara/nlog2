require 'time'
require 'sinatra/base'
require 'sinatra/reloader'
require 'bcrypt'
require 'slim'
require 'sass'
require 'sinatra/activerecord'
require 'active_support/core_ext/date'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'kaminari/sinatra'
require 'active_support/core_ext/object/to_query'

class Post < ActiveRecord::Base
  validates_presence_of :body
  validates_presence_of :datetime
  validates_presence_of :published_at

  def permanent?
    permanent
  end

  def url
    URI.join(NLog2.config[:blog][:url], path_to_show).to_s
  end

  def page_title
    "#{self.title} - #{NLog2.config[:blog][:title]}"
  end

  def path_to_show
    if permanent?
      "/#{slug_or_id}"
    else
      self.author_datetime.strftime("/%Y/%m/%d/#{slug_or_id}")
    end
  end

  def path_to_edit
    "/_edit/#{self.id}"
  end
  
  def author_date
    author_datetime.to_date
  end

  def author_datetime
    self.datetime.in_time_zone
  end

  def slug_or_id
    return slug if slug && !slug.empty?
    return self.id.to_s
  end

  class HtmlWithRouge < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end
  def rendered_body
    markdown = Redcarpet::Markdown.new(HtmlWithRouge,
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      footnotes: true,
    )
    markdown.render(self.body)
  end

  # Social buttons

  def twitter_button
    href = "https://twitter.com/intent/tweet" +
           "?text=#{Rack::Utils.escape self.page_title}" +
           "&url=#{Rack::Utils.escape self.url}"
    "<a class='twitter-share-button' href=#{Rack::Utils.escape_html href}>Tweet</a>"
  end

  def facebook_button
    [
      "<div class='fb-share-button'",
      "data-href='#{Rack::Utils.escape_html self.url}'",
      "data-layout='button'",
      "data-size='small'",
      "data-mobile-iframe='true'>",
        "<a class='fb-xfbml-parse-ignore'",
        "target='_blank'",
        "href='https://www.facebook.com/sharer/sharer.php?u=#{Rack::Utils.escape_html self.url}'>",
          "Share",
        "</a>",
      "</div>"
    ].join(" ")
  end
  
  def hatena_bookmark_button
    b_url = "http://b.hatena.ne.jp/entry/" + self.url.sub(%r{\Ahttps?://}, "")
    [
      "<a href='#{b_url}'",
        "class='hatena-bookmark-button'",
        "data-hatena-bookmark-title='#{Rack::Utils.escape_html self.page_title}'",
        "data-hatena-bookmark-layout='standard-noballoon'",
        "data-hatena-bookmark-lang='ja'",
        "title='Add this entry to Hatena Bookmark'>",
        "<img src='https://b.st-hatena.com/images/entry-button/button-only@2x.png'",
        "alt='Add this entry to Hatena Bookmark'",
        "width='20' height='20' style='border: none;'>",
      "</a>"
    ].join(" ")
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
    @posts = Post.where(permanent: false)
                 .order(datetime: :desc).page(params[:page]).per(10)
    slim :index
  end

  get '/_list' do
    @posts = Post.where(permanent: false)
                 .order(datetime: :desc).page(params[:page]).per(100)
    slim :list
  end

  get %r{/(\d\d\d\d)/(\d\d)/(\d\d)/(.+)} do
    *date, slug_or_id = *params[:captures]
    d = Date.new(*date.map(&:to_i))
    range = d.in_time_zone...(d+1).in_time_zone

    cond = Post.where(permanent: false, slug: slug_or_id)
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
    @feed_posts = Post.where(permanent: false)
                      .order(datetime: :desc).limit(10)
    builder :_feed
  end

  #
  # Edit
  #
  
  get '/_edit' do redirect '/_edit/' end
  get '/_edit/:id?' do
    authenticate!
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
    @flash_error = nil
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
      @flash_error = "Failed to parse date: #{params[:datetime].inspect}"
      @post.datetime = Time.now
    end

    if params[:submit_by] == "Save" && !@flash_error
      @post.published_at ||= Time.now
      @post.save!
      redirect @post.path_to_show
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
    @post = Post.where(permanent: true, slug: name).first
    raise Sinatra::NotFound unless @post
    @title = @post.title
    slim :show
  end
end

NLog2.load_config("#{__dir__}/config/nlog2.yml")
