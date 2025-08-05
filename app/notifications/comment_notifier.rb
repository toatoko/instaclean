class CommentNotifier < ApplicationNotifier

  param :comment, :commenter, :post

  def message
    commenter_username = params[:commenter]&.username || "Someone"
    comment_content = params[:comment]&.content&.truncate(30) || "something"
    "#{commenter_username} commented on your post: \"#{comment_content}\""
  end

  def url
    Rails.application.routes.url_helpers.post_path(params[:post]) if params[:post]
  end
end
