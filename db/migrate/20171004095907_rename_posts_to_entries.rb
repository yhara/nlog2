class RenamePostsToEntries < ActiveRecord::Migration[5.1]
  def up
    rename_table :posts, :entries

    Post.where(permanent: true).find_each do |post|
      post.update_columns(type: "Article")
    end

    remove_column :entries, :permanent
  end

  def down
    add_column :entries, :permanent

    Article.find_each do |article|
      article.update_columns(type: "Post", permanent: true)
    end

    rename_table :entries, :posts
  end
end
