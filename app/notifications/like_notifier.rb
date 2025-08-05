class LikeNotifier < ApplicationNotifier
  param :liker, :post

  def message
    liker_username = params[:liker]&.username || "Someone"
    post_description = params[:post]&.description&.truncate(30) || "a post"
    "#{liker_username} liked your post: \"#{post_description}\""
  end

  def url
    Rails.application.routes.url_helpers.post_path(params[:post]) if params[:post]
  end
end
