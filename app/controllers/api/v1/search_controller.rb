class Api::V1::SearchController < Api::V1::BaseController
  def index
    @query = params[:q].to_s.strip

    if @query.blank?
      return render_error("Search query cannot be empty", :bad_request)
    end

    # Use your User.visible_to scope for proper filtering
    visible_users = User.visible_to(current_user)
                       .where(
                         "username ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q",
                         q: "%#{@query}%"
                       )
                       .includes(:avatar_attachment)
                       .limit(20)

    # Search posts from visible users
    visible_user_ids = User.visible_to(current_user).pluck(:id)

    @posts = Post.includes(:image_attachment, :user, user: [ :avatar_attachment ])
                 .where(user_id: visible_user_ids)
                 .where(active: true)
                 .where(
                   "posts.description ILIKE :q",
                   q: "%#{@query}%"
                 )
                 .limit(20)

    # Format users data
    users_data = visible_users.map do |user|
      {
        id: user.id,
        username: user.username,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        bio: user.bio,
        avatar: user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil,
        followers_count: user.followers_count,
        is_following: current_user&.following?(user) || false
      }
    end

    # Format posts data
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
      query: @query,
      users: users_data,
      posts: posts_data,
      users_count: users_data.length,
      posts_count: posts_data.length
    })
  end
end
