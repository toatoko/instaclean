class ReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    @report = current_user.submitted_reports.build(report_params)
    if @report.save
      redirect_back fallback_location: root_path, notice: "Report submitted successfully."
    else
      redirect_back fallback_location: root_path, alert: "Failed to submit report."
    end
  end

  private

  def report_params
    params.require(:report).permit(:reportable_type, :reportable_id, :reason)
  end
end
