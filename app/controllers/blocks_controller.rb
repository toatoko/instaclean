class BlocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, except: [ :index ]

  def index
    @blocked_users = current_user.blocked_users
                                 .includes(:avatar_attachment)
                                 .order(:username)

    if defined?(Kaminari)
      @blocked_users = @blocked_users.page(params[:page]).per(20)
    end

    @total_blocked_users = current_user.blocked_users.count
  end

  def create
    if current_user.block_user(@user)
      current_user.unfollow(@user)
      @user.unfollow(current_user)

      redirect_back fallback_location: root_path, notice: "User has been blocked."
    else
      redirect_back fallback_location: root_path, alert: "Unable to block user."
    end
  end

  def destroy
    if current_user.unblock_user(@user)
      redirect_back fallback_location: root_path, notice: "User has been unblocked."
    else
      redirect_back fallback_location: root_path, alert: "Unable to unblock user."
    end
  end

  private

  def set_user
    # Debug: Log what we're looking for
    Rails.logger.debug "BlocksController: Looking for user with username: #{params[:username]}"
    Rails.logger.debug "BlocksController: All params: #{params.inspect}"

    # Handle both :username and :user_username params (in case of nested routes)
    username = params[:username] || params[:user_username]

    unless username.present?
      Rails.logger.error "BlocksController: No username parameter found"
      redirect_to root_path, alert: "User parameter missing."
      return
    end

    @user = User.find_by(username: username)

    unless @user
      Rails.logger.error "BlocksController: User not found with username: #{username}"
      # Check if user exists with different case
      similar_user = User.where("LOWER(username) = ?", username.downcase).first
      if similar_user
        Rails.logger.error "BlocksController: Found similar user with different case: #{similar_user.username}"
      end
      redirect_to root_path, alert: "User not found."
      return
    end

    if current_user == @user
      redirect_back fallback_location: root_path, alert: "You cannot block yourself."
      return
    end

    Rails.logger.debug "BlocksController: Found user: #{@user.username} (ID: #{@user.id})"
  end
end
