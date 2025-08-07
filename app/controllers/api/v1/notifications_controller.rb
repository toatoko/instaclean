class Api::V1::NotificationsController < Api::V1::BaseController
  def index
    # Get notifications with pagination
    @notifications = current_user.notifications
                                .order(created_at: :desc)
                                .page(params[:page]).per(20)

    notifications_data = @notifications.map do |notification|
      {
        id: notification.id,
        type: notification.type,
        message: notification.message, # Use your model method
        read: notification.read_at.present?,
        created_at: notification.created_at,
        url: notification.notification_url, # Use your model method
        icon: notification.notification_icon, # Use your model method
        user: format_notification_user(notification.notification_user) # Use your model method
      }
    end

    # Get counts
    total_count = current_user.notifications.count
    unread_count = current_user.notifications.unread.count

    render_success({
      notifications: notifications_data,
      has_more: @notifications.next_page.present?,
      current_page: @notifications.current_page,
      total_count: total_count,
      unread_count: unread_count
    })
  end

  def mark_as_read
    if params[:id].present?
      # Mark specific notification as read
      notification = current_user.notifications.find_by(id: params[:id])
      if notification
        notification.mark_as_read!
        render_success({}, "Notification marked as read")
      else
        render_not_found("Notification not found")
      end
    else
      render_error("Notification ID required", :bad_request)
    end
  end

  def mark_all_as_read
    count = current_user.notifications.unread.count
    current_user.notifications.unread.mark_as_read!
    render_success({ count: count }, "#{count} notifications marked as read")
  end

  private

  def format_notification_user(user)
    return nil unless user

    {
      id: user.id,
      username: user.username,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      avatar: user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil
    }
  end
end
