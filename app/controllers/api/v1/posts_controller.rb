class Api::V1::PostsController < Api::V1::BaseController
  before_action :set_post, only: [ :show, :update, :destroy, :toggle_like ]

  def index
    # Use your User.visible_to scope for proper filtering
    visible_user_ids = User.visible_to(current_user).pluck(:id)

    @posts = Post.joins(:user)
                 .where(user_id: visible_user_ids)
                 .includes([ :image_attachment, :user, user: [ :avatar_attachment ] ])
                 .where(active: true)
                 .order(created_at: :desc)
                 .page(params[:page]).per(20)

    posts_data = @posts.map do |post|
      {
        id: post.id,
        description: post.description,
        images: post.image.attached? ? [ Rails.application.routes.url_helpers.rails_blob_url(post.image, only_path: false) ] : [],
        likes_count: post.likes_count,
        comments_count: post.comments_count,
        is_liked: current_user && post.liked_by?(current_user),
        created_at: post.created_at,
        user: {
          id: post.user.id,
          username: post.user.username,
          first_name: post.user.first_name,
          last_name: post.user.last_name,
          full_name: post.user.full_name,
          avatar: post.user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(post.user.avatar, only_path: false) : nil
        }
      }
    end

    render_success({
      posts: posts_data,
      has_more: @posts.next_page.present?,
      current_page: @posts.current_page,
      total_pages: @posts.total_pages
    })
  end

  def show
    # Check if post is accessible using your model method
    if !@post.active? || !@post.user.content_visible_to?(current_user)
      return render_not_found("Post not found")
    end

    post_data = {
      id: @post.id,
      description: @post.description,
      images: @post.image.attached? ? [ Rails.application.routes.url_helpers.rails_blob_url(@post.image, only_path: false) ] : [],
      likes_count: @post.likes_count,
      comments_count: @post.comments_count,
      is_liked: current_user && @post.liked_by?(current_user),
      created_at: @post.created_at,
      user: {
        id: @post.user.id,
        username: @post.user.username,
        first_name: @post.user.first_name,
        last_name: @post.user.last_name,
        full_name: @post.user.full_name,
        avatar: @post.user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(@post.user.avatar, only_path: false) : nil
      }
    }

    render_success(post_data)
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      post_data = {
        id: @post.id,
        description: @post.description,
        images: @post.image.attached? ? [ Rails.application.routes.url_helpers.rails_blob_url(@post.image, only_path: false) ] : [],
        likes_count: 0,
        comments_count: 0,
        is_liked: false,
        created_at: @post.created_at,
        user: {
          id: current_user.id,
          username: current_user.username,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          full_name: current_user.full_name,
          avatar: current_user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(current_user.avatar, only_path: false) : nil
        }
      }
      render_success(post_data, "Post created successfully", :created)
    else
      render_error("Unable to create post", :unprocessable_entity, @post.errors.full_messages)
    end
  end

  def update
    # Check if user owns the post
    if @post.user != current_user
      return render_error("You can only edit your own posts", :forbidden)
    end

    if @post.update(post_params)
      post_data = {
        id: @post.id,
        description: @post.description,
        images: @post.image.attached? ? [ Rails.application.routes.url_helpers.rails_blob_url(@post.image, only_path: false) ] : [],
        likes_count: @post.likes_count,
        comments_count: @post.comments_count,
        is_liked: @post.liked_by?(current_user),
        created_at: @post.created_at,
        updated_at: @post.updated_at
      }
      render_success(post_data, "Post updated successfully")
    else
      render_error("Unable to update post", :unprocessable_entity, @post.errors.full_messages)
    end
  end

  def destroy
    # Check if user owns the post
    if @post.user != current_user
      return render_error("You can only delete your own posts", :forbidden)
    end

    if @post.destroy
      render_success({}, "Post deleted successfully")
    else
      render_error("Unable to delete post")
    end
  end

  def toggle_like
    like = @post.likes.find_by(user: current_user)

    if like
      like.destroy
      liked = false
      message = "Post unliked"

      # Send notification if not liking own post
      if @post.user != current_user
        # Note: You might want to remove the like notification here
      end
    else
      @post.likes.create(user: current_user)
      liked = true
      message = "Post liked"

      # Send notification if not liking own post
      if @post.user != current_user
        LikeNotifier.with(liker: current_user, post: @post).deliver_later(@post.user)
      end
    end

    render_success({
      liked: liked,
      likes_count: @post.reload.likes_count
    }, message)
  end

  private

  def set_post
    @post = Post.find_by(id: params[:id])
    unless @post
      render_not_found("Post not found")
    end
  end

  def post_params
    params.require(:post).permit(:description, :image)
  end
end
