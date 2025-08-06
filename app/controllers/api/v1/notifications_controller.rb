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
        message: notification_message(notification),
        read: notification.read_at.present?,
        created_at: notification.created_at,
        data: notification.params # Contains the notification data
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

  def notification_message(notification)
    # Generate user-friendly messages based on notification type
    case notification.type
    when "FollowNotifier"
      follower = notification.params[:follower]
      "#{follower['username']} started following you"
    when "LikeNotifier"
      liker = notification.params[:liker]
      "#{liker['username']} liked your post"
    when "CommentNotifier"
      commenter = notification.params[:commenter]
      "#{commenter['username']} commented on your post"
    else
      "New notification"
    end
  end
end
