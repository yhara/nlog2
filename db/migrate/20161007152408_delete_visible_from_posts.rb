class DeleteVisibleFromPosts < ActiveRecord::Migration[5.0]
  def change
    remove_column :posts, :visible, :boolean
  end
end
