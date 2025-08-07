class Api::V1::BlocksController < Api::V1::BaseController
  before_action :set_user, only: [ :create, :destroy ]

  def index
    @blocked_users = current_user.blocked_users
                                .includes(:avatar_attachment)
                                .order(:username)
                                .page(params[:page]).per(20)

    blocked_users_data = @blocked_users.map do |user|
      {
        id: user.id,
        username: user.username,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        bio: user.bio,
        avatar: user.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false) : nil
      }
    end

    render_success({
      blocked_users: blocked_users_data,
      has_more: @blocked_users.next_page.present?,
      total_count: current_user.blocked_users.count
    })
  end

  def create
    if current_user == @user
      return render_error("You cannot block yourself", :bad_request)
    end

    if current_user.block_user(@user)
      # Unfollow each other when blocking
      current_user.unfollow(@user)
      @user.unfollow(current_user)

      render_success({
        blocked_user: {
          id: @user.id,
          username: @user.username,
          first_name: @user.first_name,
          last_name: @user.last_name,
          full_name: @user.full_name
        }
      }, "User has been blocked")
    else
      render_error("Unable to block user")
    end
  end

  def destroy
    if current_user.unblock_user(@user)
      render_success({}, "User has been unblocked")
    else
      render_error("Unable to unblock user")
    end
  end

  private

  def set_user
    username = params[:username] || params[:user_username]

    unless username.present?
      return render_error("Username parameter required", :bad_request)
    end

    @user = User.find_by(username: username)
    unless @user
      render_not_found("User not found")
    end
  end
end
