class Api::V1::ReportsController < Api::V1::BaseController
  def create
    @report = current_user.submitted_reports.build(report_params)

    if @report.save
      render_success({
        report_id: @report.id,
        status: @report.status
      }, "Report submitted successfully", :created)
    else
      render_error("Failed to submit report", :unprocessable_entity, @report.errors.full_messages)
    end
  end

  private

  def report_params
    params.require(:report).permit(:reportable_type, :reportable_id, :reason)
  end
end
