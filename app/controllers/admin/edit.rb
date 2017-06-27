class NLog2 < Sinatra::Base
  get '/_admin/edit' do redirect '/_admin/edit/' end
  get '/_admin/edit/:id?' do
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

  post '/_admin/edit' do
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
    @post.category = Category.find_by!(id: params[:category].to_i)

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
end
