class NLog2 < Sinatra::Base
  # View Helpers
  helpers do
    KEEP_KEYS = [:category, :per]
    def keep_params
      return KEEP_KEYS.map{|s| [s, params[s]]}
             .reject{|k, v| v.nil?}
             .to_h
    end

    def previous_page_path(scope)
      return nil if scope.first_page?
      query = keep_params.merge(page: scope.prev_page)
      return env['PATH_INFO'] + (query.empty? ? '' : "?#{query.to_query}")
    end

    def next_page_path(scope)
      return nil if scope.last_page?
      query = keep_params.merge(page: scope.next_page)
      return env['PATH_INFO'] + (query.empty? ? '' : "?#{query.to_query}")
    end
  end

  def per_in(rng)
    return rng.end if params[:per].nil?
    per = params[:per].to_i
    return rng.begin if per < rng.begin
    return rng.end if per > rng.end
    return per
  end

  get '/' do
    @posts = Post.published
                 .where(permanent: false)
                 .order(datetime: :desc)
                 .page(params[:page]).per(per_in(1..10))
    slim :index
  end

  get '/_list' do
    if (cat_name = params[:category])
      @category = Category.find_by!(name: cat_name)
    else
      @category = nil
    end

    @posts = Post.published
                 .with_category(@category)
                 .where(permanent: false)
                 .order(datetime: :desc)
                 .page(params[:page]).per(per_in(1..100))
    @articles = Post.published
                    .with_category(@category)
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
    if params[:nodiary] == "1"
      # Note: issues 404 if no such category
      cat = Category.find_by!(name: "Diary")
      @feed_posts = Post.published
                        .where(permanent: false)
                        .without_category(cat)
                        .order(datetime: :desc).limit(10)
      @title_suffix = " (without diary)"
    else
      @feed_posts = Post.published
                        .where(permanent: false)
                        .order(datetime: :desc).limit(10)
      @title_suffix = ""
    end
    builder :_feed
  end
end
