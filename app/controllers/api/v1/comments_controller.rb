class Api::V1::CommentsController < Api::V1::BaseController
  before_action :set_post
  before_action :set_comment, only: [ :destroy ]

  def index
    # Only show comments from users visible to current user
    visible_user_ids = User.visible_to(current_user).pluck(:id)

    @comments = @post.comments.joins(:user)
                     .where(user_id: visible_user_ids)
                     .includes(:user, user: [ :avatar_attachment ])
                     .recent
                     .page(params[:page]).per(20)

    comments_data = @comments.map do |comment|
      {
        id: comment.id,
        content: comment.content,
        created_at: comment.created_at,
        user: {
          id: comment.user.id,
          username: comment.user.username,
          first_name: comment.user.first_name,
          last_name: comment.user.last_name,
          full_name: comment.user.full_name,
          avatar: comment.user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(comment.user.avatar, only_path: false) : nil
        }
      }
    end

    render_success({
      comments: comments_data,
      has_more: @comments.next_page.present?,
      current_page: @comments.current_page,
      total_count: @post.comments_count
    })
  end

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      # Send notification if not commenting on own post
      if @post.user != current_user
        CommentNotifier.with(comment: @comment, commenter: current_user, post: @post).deliver_later(@post.user)
      end

      comment_data = {
        id: @comment.id,
        content: @comment.content,
        created_at: @comment.created_at,
        user: {
          id: current_user.id,
          username: current_user.username,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          full_name: current_user.full_name,
          avatar: current_user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(current_user.avatar, only_path: false) : nil
        }
      }

      render_success(comment_data, "Comment added successfully", :created)
    else
      render_error("Unable to create comment", :unprocessable_entity, @comment.errors.full_messages)
    end
  end

  def destroy
    # Check if user can delete this comment (owner or post owner)
    unless @comment.user == current_user || @post.user == current_user
      return render_error("You can only delete your own comments", :forbidden)
    end

    if @comment.destroy
      render_success({}, "Comment deleted successfully")
    else
      render_error("Unable to delete comment")
    end
  end

  private

  def set_post
    @post = Post.find_by(id: params[:post_id])
    unless @post
      render_not_found("Post not found")
    end

    # Check if post is visible to current user
    unless @post.user.content_visible_to?(current_user)
      render_not_found("Post not found")
    end
  end

  def set_comment
    @comment = @post.comments.find_by(id: params[:id])
    unless @comment
      render_not_found("Comment not found")
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
