class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [ :show, :follow, :unfollow ]

  def index
    # Similar to web controller but return JSON
    if current_user
      blocked_user_ids = current_user.blocking_relationships.pluck(:blocked_id)
      blocked_by_user_ids = current_user.blocked_relationships.pluck(:blocker_id)
      excluded_user_ids = (blocked_user_ids + blocked_by_user_ids).uniq
    else
      excluded_user_ids = []
    end

    @posts = Post.joins(:user)
      .where(users: { banned_at: nil })
      .where.not(user_id: excluded_user_ids)
      .includes([ :image_attachment, user: [ :avatar_attachment ] ])
      .where(active: true)
      .order(created_at: :desc)
      .page(params[:page]).per(12)

    posts_data = @posts.map do |post|
      {
        id: post.id,
        content: post.content,
        images: post.image.attached? ? [ post.image.url ] : [],
        likes_count: post.likes.count,
        comments_count: post.comments.count,
        created_at: post.created_at,
        user: {
          id: post.user.id,
          username: post.user.username,
          name: post.user.name,
          avatar: post.user.avatar.attached? ? post.user.avatar.url : nil
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
    # Check if user's content should be visible
    if current_user && @user != current_user && !@user.content_visible_to?(current_user)
      return render_not_found("This profile is not available.")
    end

    @posts = @user.posts.includes(:image_attachment)
                  .where(active: true)
                  .order(created_at: :desc)

    posts_data = @posts.map do |post|
      {
        id: post.id,
        content: post.content,
        images: post.image.attached? ? [ post.image.url ] : [],
        likes_count: post.likes.count,
        comments_count: post.comments.count,
        created_at: post.created_at
      }
    end

    user_data = {
      id: @user.id,
      username: @user.username,
      name: @user.name,
      bio: @user.bio,
      avatar: @user.avatar.attached? ? @user.avatar.url : nil,
      followers_count: @user.followers.count,
      following_count: @user.following.count,
      posts_count: @user.posts.where(active: true).count,
      is_following: current_user != @user && current_user.following.exists?(id: @user.id),
      is_blocked: current_user.blocked?(@user),
      blocked_by: current_user.blocked_by?(@user),
      posts: posts_data
    }

    render_success(user_data)
  end

  def suggested
    if current_user
      blocked_user_ids = current_user.blocking_relationships.pluck(:blocked_id)
      blocked_by_user_ids = current_user.blocked_relationships.pluck(:blocker_id)
      excluded_user_ids = (blocked_user_ids + blocked_by_user_ids).uniq
    else
      excluded_user_ids = []
    end

    @suggested_users = User.active
      .all_except(current_user)
      .where.not(id: excluded_user_ids)
      .includes(:avatar_attachment)
      .limit(10)

    users_data = @suggested_users.map do |user|
      {
        id: user.id,
        username: user.username,
        name: user.name,
        bio: user.bio,
        avatar: user.avatar.attached? ? user.avatar.url : nil,
        followers_count: user.followers.count,
        is_following: current_user.following.exists?(id: user.id)
      }
    end

    render_success(users_data)
  end

  def follow
    if current_user.mutually_blocked?(@user)
      return render_error("Cannot follow this user.")
    end

    if current_user.follow(@user)
      # Send notification (adapt your existing notifier)
      FollowNotifier.with(follower: current_user, followed_user: @user).deliver_later(@user)
      render_success({ message: "Successfully followed #{@user.username}" })
    else
      render_error("Unable to follow user")
    end
  end

  def unfollow
    if current_user.unfollow(@user)
      render_success({ message: "Successfully unfollowed #{@user.username}" })
    else
      render_error("Unable to unfollow user")
    end
  end

  def update
    if current_user.update(user_params)
      user_data = {
        id: current_user.id,
        username: current_user.username,
        name: current_user.name,
        bio: current_user.bio,
        email: current_user.email,
        avatar: current_user.avatar.attached? ? current_user.avatar.url : nil
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
  end

  def user_params
    params.require(:user).permit(:name, :username, :bio, :email, :avatar)
  end
end
