require 'active_record'

class Post < ActiveRecord::Base
  belongs_to :category

  validates_presence_of :body, :title, :datetime, :published_at

  scope :published, ->{ where('datetime <= ?', Time.now) }
  scope :future, ->{ where('datetime > ?', Time.now) }
  scope :uncategorized, ->{ where('category_id IS NULL') }
  scope :with_category_if, ->(cat){
    if cat
      where(category: cat)
    else
      all
    end
  }
  scope :without_category, ->(cat){
    where.not(category: cat).or(Post.where('category_id IS NULL'))
  }

  def permanent?
    permanent
  end

  def future?
    self.datetime > Time.now
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
    "/_admin/edit/#{self.id}"
  end
  
  def author_date
    author_datetime.to_date
  end

  def author_datetime
    self.datetime.in_time_zone
  end

  def author_updated_at
    self.updated_at.in_time_zone
  end

  def slug_or_id
    return slug if slug && !slug.empty?
    return self.id.to_s
  end

  def rendered_body
    render_markdown(self.body)
  end

  # Return shortened version of HTML
  # Return nil if the body is already short enough
  SHORTEN_TO = 10
  SHORTEN_MORE_THAN = 15
  def short_body
    lines = self.body.strip.lines
    if lines.count <= SHORTEN_MORE_THAN
      nil
    else
      lines = lines.first(SHORTEN_TO)
      if lines.last.start_with?("#")
        lines.pop
      end
      render_markdown(lines.join)
    end
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

  private
  
  class HtmlWithRouge < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end
  def render_markdown(str)
    markdown = Redcarpet::Markdown.new(HtmlWithRouge,
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      footnotes: true,
    )
    return markdown.render(str)
  end

end
