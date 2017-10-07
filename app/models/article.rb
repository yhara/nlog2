require_relative 'entry'

class Article < Entry
  def path_to_show
    "/#{slug_or_id}"
  end
end
