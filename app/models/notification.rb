class Notification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true

  # Add this method to safely access notification data
  def notification_data
    # Ensure params is always a hash
    safe_params = case params
    when Hash
                    params
    when String
                    begin
                      JSON.parse(params)
                    rescue JSON::ParserError
                      {}
                    end
    when nil
                    {}
    else
                    {}
    end

    # Try to access the stored parameters
    case self.type
    when "FollowNotifier"
      {
        follower: safe_params[:follower] || safe_params["follower"],
        follower_username: (safe_params[:follower] || safe_params["follower"])&.username || safe_params[:follower_username] || safe_params["follower_username"],
        followed_user: safe_params[:followed_user] || safe_params["followed_user"]
      }
    when "CommentNotifier"
      {
        commenter: safe_params[:commenter] || safe_params["commenter"],
        commenter_username: (safe_params[:commenter] || safe_params["commenter"])&.username,
        comment: safe_params[:comment] || safe_params["comment"],
        post: safe_params[:post] || safe_params["post"]
      }
    when "LikeNotifier"
      {
        liker: safe_params[:liker] || safe_params["liker"],
        liker_username: (safe_params[:liker] || safe_params["liker"])&.username,
        post: safe_params[:post] || safe_params["post"]
      }
    else
      safe_params
    end
  end

  # Improved to_notifier method
  def to_notifier
    notifier_class = self.type.safe_constantize
    if notifier_class && notifier_class < Noticed::Base
      # Ensure params is a hash before passing
      safe_params = notification_data
      notifier_class.new(params: safe_params)
    else
      Rails.logger.error "ERROR: Invalid notifier type for Notification ID #{self.id}: #{self.type}"
      nil
    end
  end

  # Helper methods for the view
  def message
    data = notification_data

    case self.type
    when "FollowNotifier"
      follower_username = data[:follower_username] || "Someone"
      "#{follower_username} started following you."
    when "CommentNotifier"
      commenter_username = data[:commenter_username] || "Someone"
      comment_content = data[:comment]&.content&.truncate(30) || "something"
      "#{commenter_username} commented on your post: \"#{comment_content}\""
    when "LikeNotifier"
      liker_username = data[:liker_username] || "Someone"
      post_description = data[:post]&.description&.truncate(30) || "a post"
      "#{liker_username} liked your post: \"#{post_description}\""
    else
      "New notification"
    end
  end

  def notification_url
    data = notification_data

    case self.type
    when "FollowNotifier"
      follower = data[:follower]
      Rails.application.routes.url_helpers.profile_path(follower.username) if follower&.username
    when "CommentNotifier", "LikeNotifier"
      post = data[:post]
      Rails.application.routes.url_helpers.post_path(post) if post
    end
  end

  def notification_icon
    case self.type
    when "CommentNotifier"
      "comment"
    when "LikeNotifier"
      "heart"
    when "FollowNotifier"
      "user-plus"
    else
      "bell"
    end
  end

  def notification_user
    data = notification_data

    case self.type
    when "FollowNotifier"
      data[:follower]
    when "CommentNotifier"
      data[:commenter]
    when "LikeNotifier"
      data[:liker]
    end
  end
end
