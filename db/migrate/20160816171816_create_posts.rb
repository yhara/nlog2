class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.string :slug
      t.datetime :published_at
      t.text :body
      t.boolean :published

      t.timestamps
    end
  end
end
