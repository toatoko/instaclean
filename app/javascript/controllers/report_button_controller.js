// app/javascript/controllers/report_button_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { reportableType: String, reportableId: Number }

    connect() {
    }

    triggerReportModal() {
        const event = new CustomEvent("report:open", {
            bubbles: true,
            cancelable: true,
            detail: {
                reportableType: this.reportableTypeValue,
                reportableId: this.reportableIdValue
            }
        });
        this.element.dispatchEvent(event);
    }
}
