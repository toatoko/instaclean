class AddUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string, limit: 15
    add_index :users, :username, unique: true
  end
end
