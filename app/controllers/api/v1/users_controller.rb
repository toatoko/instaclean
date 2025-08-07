class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [ :show, :follow, :unfollow, :followers, :following ]

  def index
    # Use your User.visible_to scope
    visible_user_ids = User.visible_to(current_user).pluck(:id)

    @posts = Post.joins(:user)
                 .where(user_id: visible_user_ids)
                 .includes([ :image_attachment, user: [ :avatar_attachment ] ])
                 .where(active: true)
                 .order(created_at: :desc)
                 .page(params[:page]).per(12)

    posts_data = @posts.map do |post|
      {
        id: post.id,
        description: post.description,
        images: post.image.attached? ? [ Rails.application.routes.url_helpers.rails_blob_url(post.image, only_path: false) ] : [],
        likes_count: post.likes_count,
        comments_count: post.comments_count,
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
      current_page: @posts.current_page
    })
  end

  def show
    # Check if user's content should be visible using your model method
    unless @user.content_visible_to?(current_user)
      return render_not_found("This profile is not available.")
    end

    @posts = @user.posts.includes(:image_attachment)
                  .where(active: true)
                  .order(created_at: :desc)

    posts_data = @posts.map do |post|
      {
        id: post.id,
        description: post.description,
        images: post.image.attached? ? [ Rails.application.routes.url_helpers.rails_blob_url(post.image, only_path: false) ] : [],
        likes_count: post.likes_count,
        comments_count: post.comments_count,
        created_at: post.created_at
      }
    end

    user_data = {
      id: @user.id,
      username: @user.username,
      first_name: @user.first_name,
      last_name: @user.last_name,
      full_name: @user.full_name,
      bio: @user.bio,
      avatar: @user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(@user.avatar, only_path: false) : nil,
      followers_count: @user.followers_count,
      following_count: @user.following_count,
      posts_count: @user.posts_count,
      is_following: current_user != @user && current_user&.following?(@user),
      is_blocked: current_user&.blocked?(@user),
      blocked_by: current_user&.blocked_by?(@user),
      posts: posts_data
    }

    render_success(user_data)
  end

  def suggested
    # Use your User.visible_to scope
    @suggested_users = User.visible_to(current_user)
                           .all_except(current_user)
                           .includes(:avatar_attachment)
                           .limit(10)

    users_data = @suggested_users.map do |user|
      {
        id: user.id,
        username: user.username,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        bio: user.bio,
        avatar: user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil,
        followers_count: user.followers_count,
        is_following: current_user&.following?(user)
      }
    end

    render_success(users_data)
  end

  def follow
    if current_user.mutually_blocked?(@user)
      return render_error("Cannot follow this user.")
    end

    if current_user.follow(@user)
      # Send notification
      FollowNotifier.with(follower: current_user, followed_user: @user).deliver_later(@user)
      render_success({
        message: "Successfully followed #{@user.username}",
        is_following: true,
        followers_count: @user.reload.followers_count
      })
    else
      render_error("Unable to follow user")
    end
  end

  def unfollow
    if current_user.unfollow(@user)
      render_success({
        message: "Successfully unfollowed #{@user.username}",
        is_following: false,
        followers_count: @user.reload.followers_count
      })
    else
      render_error("Unable to unfollow user")
    end
  end

  # GET /api/v1/users/:username/followers
  def followers
    # Use your model method for getting visible followers
    @followers = @user.visible_followers(current_user)
                      .includes(:avatar_attachment)
                      .page(params[:page]).per(20)

    followers_data = @followers.map do |follower|
      {
        id: follower.id,
        username: follower.username,
        first_name: follower.first_name,
        last_name: follower.last_name,
        full_name: follower.full_name,
        bio: follower.bio,
        avatar: follower.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(follower.avatar, only_path: false) : nil,
        followers_count: follower.followers_count,
        is_following: current_user&.following?(follower) || false,
        is_blocked: current_user&.blocked?(follower) || false
      }
    end

    render_success({
      followers: followers_data,
      has_more: @followers.next_page.present?,
      current_page: @followers.current_page,
      total_count: @user.followers_count
    })
  end

  # GET /api/v1/users/:username/following
  def following
    # Use your model method for getting visible following
    @following = @user.visible_following(current_user)
                      .includes(:avatar_attachment)
                      .page(params[:page]).per(20)

    following_data = @following.map do |followed|
      {
        id: followed.id,
        username: followed.username,
        first_name: followed.first_name,
        last_name: followed.last_name,
        full_name: followed.full_name,
        bio: followed.bio,
        avatar: followed.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(followed.avatar, only_path: false) : nil,
        followers_count: followed.followers_count,
        is_following: current_user&.following?(followed) || false,
        is_blocked: current_user&.blocked?(followed) || false
      }
    end

    render_success({
      following: following_data,
      has_more: @following.next_page.present?,
      current_page: @following.current_page,
      total_count: @user.following_count
    })
  end

  def update
    if current_user.update(user_params)
      user_data = {
        id: current_user.id,
        username: current_user.username,
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        full_name: current_user.full_name,
        bio: current_user.bio,
        email: current_user.email,
        avatar: current_user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(current_user.avatar, only_path: false) : nil
      }
      render_success(user_data, "Profile updated successfully")
    else
      render_error("Unable to update profile", :unprocessable_entity, current_user.errors.full_messages)
    end
  end

  private

  def set_user
    @user = User.find_by(username: params[:username])
    unless @user
      render_not_found("User not found")
    end

    # Check if user's content should be visible (only for show, followers, following)
    if %w[show followers following].include?(params[:action]) && !@user.content_visible_to?(current_user)
      render_not_found("This profile is not available.")
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :bio, :email, :avatar)
  end
end
