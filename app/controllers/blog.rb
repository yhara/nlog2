class NLog2 < Sinatra::Base
  # View Helpers
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

  get '/' do
    @posts = Post.published
                 .where(permanent: false)
                 .order(datetime: :desc).page(params[:page]).per(10)
    slim :index
  end

  get '/_list' do
    @posts = Post.published
                 .where(permanent: false)
                 .order(datetime: :desc).page(params[:page]).per(100)
    @articles = Post.published
                    .where(permanent: true)
                    .order(updated_at: :desc)
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

  # Permanent articles (must not start with `_')
  get %r{/([^_]\w+)} do |name|
    @post = Post.published.where(permanent: true, slug: name).first
    raise Sinatra::NotFound unless @post
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
                      .order(datetime: :desc).limit(10)
    builder :_feed
  end
end
