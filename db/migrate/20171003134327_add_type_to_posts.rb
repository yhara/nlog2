class AddTypeToPosts < ActiveRecord::Migration[5.1]
  def up
    add_column :posts, "type", :string
    Post.update_all(type: "Post")
    change_column :posts, "type", :string, null: false 
  end

  def down
    remove_column :posts, "type"
  end
end
