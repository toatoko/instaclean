class AddCountersToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :comments_count, :integer, default: 0, null: false
    add_column :posts, :likes_count, :integer, default: 0, null: false
  end
end
