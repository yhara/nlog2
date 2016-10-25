class AddPermanentToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :permanent, :boolean, null: false, default: false
  end
end
