class FollowNotifier < ApplicationNotifier

  param :follower, :followed_user

  def message
    follower_username = params[:follower]&.username || "Someone"
    "#{follower_username} started following you."
  end

  def url
    Rails.application.routes.url_helpers.profile_path(params[:follower].username) if params[:follower]&.username
  end
end
