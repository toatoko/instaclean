class Admin::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_reportable, only: [ :index, :show, :resolve, :dismiss, :resolve_all ]
  before_action :set_report, only: [ :show, :resolve, :dismiss ]

  def index
    if @reportable
      @reports = Report.where(reportable: @reportable)
                      .includes(:reporter, reportable: reportable_includes_for(@reportable))
                      .order(created_at: :desc)
      @reportable_type = @reportable.class.name.downcase
    else
      # For mixed report types, include the most common associations
      base_query = Report.includes(:reporter, reportable: [ :image_attachment ])
                        .order(created_at: :desc)

      # Only include resolved_by when we might actually need it
      if params[:status].blank? || params[:status].in?([ "resolved", "dismissed" ])
        base_query = base_query.includes(:resolved_by)
      end

      @reports = params[:status].present? ? base_query.where(status: params[:status]) : base_query
    end
  end

  def show
  end

  def resolve
    @report.update(status: "resolved", resolved_by: current_user, resolved_at: Time.current)

    case params[:action_type]
    when "delete_content"
      @reportable.destroy
      redirect_to admin_reports_path, notice: "Report resolved and #{@reportable.class.name.downcase} deleted."
    when "warn_user"
      # Implement user warning system here
      redirect_to admin_report_path(@report), notice: "Report resolved and user warned."
    else
      redirect_to admin_report_path(@report), notice: "Report resolved."
    end
  end

  def dismiss
    @report.update(status: "dismissed", resolved_by: current_user, resolved_at: Time.current)
    redirect_to admin_report_path(@report), notice: "Report dismissed."
  end

  def resolve_all
    reports = Report.where(reportable: @reportable, status: "pending")
    reports.update_all(
      status: "resolved",
      resolved_by_id: current_user.id,
      resolved_at: Time.current
    )

    redirect_to admin_reports_path,
                notice: "All reports for this #{@reportable.class.name.downcase} have been resolved."
  end

  private

  def set_reportable
    return unless params[:post_id] || params[:comment_id] || params[:user_id]

    if params[:post_id]
      @reportable = Post.find(params[:post_id])
    elsif params[:comment_id]
      @reportable = Comment.find(params[:comment_id])
    elsif params[:user_id]
      @reportable = User.find(params[:user_id])
    else
      redirect_to admin_reports_path, alert: "Invalid resource."
    end
  end

  def set_report
    @report = Report.includes(reportable: [ :image_attachment ]).find(params[:id])
    @reportable = @report.reportable
  end

  # Dynamic includes based on the specific reportable type
  def reportable_includes_for(reportable)
    case reportable
    when Post
      [ :image_attachment ]
    when Comment
      []
    when User
      [ :avatar_attachment ]
    else
      []
    end
  end

  def ensure_admin!
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end
end
