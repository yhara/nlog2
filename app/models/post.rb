require_relative 'entry'

class Post < Entry
  scope :future, ->{ where('datetime > ?', Time.now) }
  scope :uncategorized, ->{ where('category_id IS NULL') }
  scope :without_category, ->(cat){
    where.not(category: cat).or(where('category_id IS NULL'))
  }
  scope :is_not, ->(post){
    where.not(id: post.id)
  }

  def path_to_show
    if (d = self.author_datetime)
      d.strftime("/%Y/%m/%d/#{slug_or_id}")
    else
      "(TBA)"
    end
  end
  
  def author_date
    author_datetime&.to_date
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
end
