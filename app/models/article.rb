require_relative 'entry'

class Article < Entry
  validates :slug, presence: true, uniqueness: true, format: /\A[^_]/

  def path_to_show
    "/#{slug_or_id}"
  end
end
