class Api::V1::CommentsController < Api::V1::BaseController
  before_action :set_post
  before_action :set_comment, only: [ :destroy ]

  def index
    @comments = @post.comments.includes(:user, user: [ :avatar_attachment ])
                     .order(created_at: :desc)
                     .page(params[:page]).per(20)

    comments_data = @comments.map do |comment|
      {
        id: comment.id,
        content: comment.content,
        created_at: comment.created_at,
        user: {
          id: comment.user.id,
          username: comment.user.username,
          name: comment.user.name,
          avatar: comment.user.avatar.attached? ? comment.user.avatar.url : nil
        }
      }
    end

    render_success({
      comments: comments_data,
      has_more: @comments.next_page.present?,
      current_page: @comments.current_page,
      total_count: @post.comments.count
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
          name: current_user.name,
          avatar: current_user.avatar.attached? ? current_user.avatar.url : nil
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
