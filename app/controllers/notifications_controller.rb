class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Fetch unread notifications first, then all notifications
    @unread_notifications = current_user.notifications.unread.order(created_at: :desc)
    @all_notifications = current_user.notifications.order(created_at: :desc).page(params[:page]).per(10)

    # Get counts for the UI
    @total_count = current_user.notifications.count
    @unread_count = @unread_notifications.count
    @read_count = current_user.notifications.read.count
  end

  def mark_as_read
    # Find specific notification(s) to mark as read
    if params[:id].present?
      notification = current_user.notifications.find_by(id: params[:id])
      if notification
        notification.mark_as_read!
        redirect_to notifications_path, notice: "Notification marked as read."
      else
        redirect_to notifications_path, alert: "Notification not found."
      end
    else
      # Mark all unread notifications as read
      current_user.notifications.unread.mark_as_read!
      redirect_to notifications_path, notice: "All notifications marked as read."
    end
  end

  def delete_read
    read_count = current_user.notifications.read.count

    if read_count > 0
      current_user.notifications.read.destroy_all
      redirect_to notifications_path, notice: "#{read_count} read notifications deleted successfully."
    else
      redirect_to notifications_path, alert: "No read notifications to delete."
    end
  end

  def delete_all
    total_count = current_user.notifications.count

    if total_count > 0
      current_user.notifications.destroy_all
      redirect_to notifications_path, notice: "All #{total_count} notifications deleted successfully."
    else
      redirect_to notifications_path, alert: "No notifications to delete."
    end
  end
end
