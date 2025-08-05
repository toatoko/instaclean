class Admin::SearchController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @query = params[:q]&.strip
    @search_type = params[:search_type] || "all"

    if @query.present?
      @results = perform_search(@query, @search_type)
    else
      @results = {}
    end
  end

  private

  def perform_search(query, search_type)
    results = {}

    case search_type
    when "users"
      results[:users] = search_users(query)
    when "banned_users"
      results[:banned_users] = search_banned_users(query)
    when "posts"
      results[:posts] = search_posts(query) if defined?(Post)
    when "reports"
      results[:reports] = search_reports(query) if defined?(Report)
    when "all"
      results[:users] = search_users(query)
      results[:banned_users] = search_banned_users(query)
      results[:posts] = search_posts(query) if defined?(Post)
      results[:reports] = search_reports(query) if defined?(Report)
    end

    results
  end

  def search_users(query)
    User.where(banned_at: nil)
        .where("username ILIKE ? OR email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?",
               "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
        .includes(:avatar_attachment)
        .limit(10)
  end

  def search_banned_users(query)
    User.where.not(banned_at: nil)
        .where("username ILIKE ? OR email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?",
               "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
        .includes(:avatar_attachment)
        .limit(10)
  end

  def search_posts(query)
    return Post.none unless defined?(Post)

    Post.joins(:user)
        .where("posts.description ILIKE ? OR users.username ILIKE ?",
               "%#{query}%", "%#{query}%")
        .includes(:user, :image_attachment)
        .limit(10)
  end

  def search_reports(query)
    return Report.none unless defined?(Report)

    Report.joins(:reporter)
          .where("reports.reason ILIKE ? OR users.username ILIKE ?", "%#{query}%", "%#{query}%")
          .includes(:reporter)
          .limit(10)
  end

  def ensure_admin!
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end
end
