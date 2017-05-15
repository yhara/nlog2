require 'active_record'

class Category < ActiveRecord::Base
  has_many :posts

  validates_uniqueness_of :name

  NONE_TEXT = "(none)"

  def self.list
    Category.order(name: :asc).all
  end
end
