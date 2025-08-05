class Admin::AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def dashboard
    @users_count = User.count
    @recent_users = User.includes(:avatar_attachment).order(created_at: :desc).limit(5)

    if defined?(Report)
        @reports_count = Report.count
        @pending_reports_count = Report.where(status: "pending").count
        @recent_reports = Report.includes(:reporter).order(created_at: :desc).limit(5)
    else
        @reports_count = 0
        @pending_reports_count = 0
        @recent_reports = []
    end
  end


  private

  def require_admin
    redirect_to root_path, alert: "Access denied. You are not the admin" unless current_user&.admin?
  end
end
