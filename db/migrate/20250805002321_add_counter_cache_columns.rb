class AddCounterCacheColumns < ActiveRecord::Migration[8.0]
  def change
    # Add counter cache columns to users table
    add_column :users, :followers_count, :integer, default: 0, null: false
    add_column :users, :following_count, :integer, default: 0, null: false

    # Add indexes for better performance
    add_index :users, :posts_count
    add_index :users, :followers_count
    add_index :users, :following_count
    add_index :posts, :likes_count
    add_index :posts, :comments_count
  end
end
