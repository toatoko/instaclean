class Admin::BansController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_user, only: [ :create, :destroy ]

  def create
    puts "Params received in Admin::BansController#create: #{params.inspect}" # <--- Add this line

    if @user.ban!(current_user, ban_params[:reason])
      redirect_back(fallback_location: admin_users_path, notice: "User has been banned successfully.")
    else
      redirect_back(fallback_location: admin_users_path, alert: "Failed to ban user.")
    end
  end

  def destroy
    if @user.unban!
      redirect_back(fallback_location: admin_users_path, notice: "User has been unbanned successfully.")
    else
      redirect_back(fallback_location: admin_users_path, alert: "Failed to unban user.")
    end
  end

  private

  def set_user
    @user = User.find_by(username: params[:user_username])
    unless @user
      redirect_to root_path, alert: "User not found"
      nil
    end
  end

  def ensure_admin
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end

  def ban_params
    params.require(:user_ban).permit(:reason)
  end
end
