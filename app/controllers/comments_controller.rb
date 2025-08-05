class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post
  before_action :set_comment, only: [ :destroy ]

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    respond_to do |format|
      if @comment.save
        # Notification
        if @post.user != current_user
          CommentNotifier.with(comment: @comment, commenter: current_user, post: @post).deliver_later(@post.user)
        end
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.prepend("comments_list_#{@post.id}",
                                  partial: "comments/comment",
                                  locals: { comment: @comment }),
            turbo_stream.update("comments_count_#{@post.id}",
                                @post.comments.count),
            turbo_stream.replace("comment_form_#{@post.id}",
                                  partial: "comments/form",
                                  locals: { post: @post, comment: Comment.new })

          ]
        }
        format.html { redirect_to @post, notice: "Comment was successfully added." }
      else
        @comments = @post.comments.includes(:user).recent
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("comment_form_#{@post.id}",
          partial: "comments/form",
          locals: { post: @post, comment: @comment })
        }
        format.html { render "posts/show" }
      end
    end
  end


  def destroy
    if @comment.user == current_user || @post.user == current_user
      @comment.destroy
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.remove("comment_#{@comment.id}"),
            turbo_stream.update("comment_count_#{@post.id}",
                                @post.comments.count)
          ]
        }
        format.html { redirect_to @post }
      end
    else
      redirect_to @post, alert: "You can only delete your own comment"
    end
  end



  private

  def set_post
    @post = Post.find(params[:post_id])
  end


  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
