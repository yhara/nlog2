class AddTypeToPosts < ActiveRecord::Migration[5.1]
  def up
    add_column :posts, "type", :string
    con = ActiveRecord::Base.connection
    con.execute('UPDATE posts SET type = "Post"')
    change_column :posts, "type", :string, null: false 
  end

  def down
    remove_column :posts, "type"
  end
end
