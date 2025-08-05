class FixNotificationsParams < ActiveRecord::Migration[8.0]
  def up
    say "Clearing all notifications to fix parameter format issues..."

    execute "DELETE FROM notifications"

    say "All notifications cleared. New notifications will be created with proper format."
  end

  def down
    # Nothing to do here
  end
end
