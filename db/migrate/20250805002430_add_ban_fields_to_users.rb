class AddBanFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :banned_at, :datetime
    add_column :users, :banned_by_id, :integer
    add_column :users, :ban_reason, :text

    add_index :users, :banned_at
    add_index :users, :banned_by_id
    add_foreign_key :users, :users, column: :banned_by_id
  end
end
