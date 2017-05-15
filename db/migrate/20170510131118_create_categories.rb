class CreateCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :categories do |t|
      t.string :name
    end
    add_index :categories, :name, unique: true

    add_column :posts, :category_id, :integer, null: true, default: nil 
  end
end
