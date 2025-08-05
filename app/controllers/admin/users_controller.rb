class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :toggle_admin ]

  def index
    @users = User.includes([ :avatar_attachment ]).all.order(created_at: :desc)
    @users_count = @users.count
  end

  def show
  end

  def edit
  end

  def update
    # Remove password params if they're blank
    if user_params[:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot delete yourself."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted successfully."
    end
  end

  def toggle_admin
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot change your own admin status."
    else
      @user.update(admin: !@user.admin?)
      action = @user.admin? ? "granted admin access to" : "removed admin access from"
      redirect_to admin_users_path, notice: "Successfully #{action} #{@user.username}."
    end
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end

  def user_params
    params.require(:user).permit(:username, :email, :admin, :password, :password_confirmation)
  end

  def ensure_admin!
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end
end
