class Api::V1::SearchController < Api::V1::BaseController
  def index
    @query = params[:q].to_s.strip

    if @query.blank?
      return render_error("Search query cannot be empty", :bad_request)
    end

    # Search users (excluding current user and blocked users)
    if current_user
      blocked_user_ids = current_user.blocking_relationships.pluck(:blocked_id)
      blocked_by_user_ids = current_user.blocked_relationships.pluck(:blocker_id)
      excluded_user_ids = (blocked_user_ids + blocked_by_user_ids + [ current_user.id ]).uniq
    else
      excluded_user_ids = []
    end

    @users = User.includes(:avatar_attachment)
                 .where.not(id: excluded_user_ids)
                 .where(banned_at: nil)
                 .where(
                   "username ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q",
                   q: "%#{@query}%"
                 )
                 .limit(20)

    # Search posts (from non-blocked, non-banned users)
    @posts = Post.includes(:image_attachment, :user, user: [ :avatar_attachment ])
                 .joins(:user)
                 .where(users: { banned_at: nil })
                 .where.not(user_id: excluded_user_ids)
                 .where(active: true)
                 .where(
                   "posts.description ILIKE :q OR users.username ILIKE :q OR users.first_name ILIKE :q OR users.last_name ILIKE :q",
                   q: "%#{@query}%"
                 )
                 .limit(20)

    # Format users data
    users_data = @users.map do |user|
      {
        id: user.id,
        username: user.username,
        name: user.name,
        bio: user.bio,
        avatar: user.avatar.attached? ? user.avatar.url : nil,
        followers_count: user.followers.count,
        is_following: current_user&.following&.exists?(id: user.id) || false
      }
    end

    # Format posts data
    posts_data = @posts.map do |post|
      {
        id: post.id,
        content: post.description,
        images: post.image.attached? ? [ post.image.url ] : [],
        likes_count: post.likes.count,
        comments_count: post.comments.count,
        is_liked: current_user && post.likes.exists?(user: current_user),
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
      query: @query,
      users: users_data,
      posts: posts_data,
      users_count: users_data.length,
      posts_count: posts_data.length
    })
  end
end
