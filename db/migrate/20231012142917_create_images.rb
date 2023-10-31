class CreateImages < ActiveRecord::Migration[7.1]
  def change
    create_table :images do |t|
      t.string :orig_path, null: false
      t.string :thumb_path, null: false
      t.references :entry, null: true

      t.timestamps
    end
  end
end
