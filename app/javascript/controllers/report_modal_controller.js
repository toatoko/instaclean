// app/javascript/controllers/report_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal", "reportableType", "reportableId", "reason"]

    connect() {
        this.boundHandleEscape = this.handleEscape.bind(this)
        document.addEventListener("keydown", this.boundHandleEscape)

        this.boundOpenModalFromEvent = this.openModalFromEvent.bind(this);
        document.addEventListener("report:open", this.boundOpenModalFromEvent);
    }

    disconnect() {
        document.removeEventListener("keydown", this.boundHandleEscape)
        document.removeEventListener("report:open", this.boundOpenModalFromEvent);
    }

    openModalFromEvent(event) {
        const { reportableType, reportableId } = event.detail;

        // Call the internal _showModal method with the extracted data
        this._showModal(reportableType, reportableId);
    }

    // This method can be called directly by data-action if needed, or by openModalFromEvent
    open(event) {
        event.preventDefault()

        // The parentDropdown logic should ideally be handled by the button's controller
        // or if this 'open' method is triggered directly by a DOM element with data-action.
        // For now, we'll keep it but ensure currentTarget is a DOM element if this path is used.
        // If this 'open' method is ONLY called by openModalFromEvent, this block can be removed.
        if (event.currentTarget && typeof event.currentTarget.closest === 'function') {
            const parentDropdown = event.currentTarget.closest('[data-controller="dropdown"]');
            if (parentDropdown) {
                const dropdownMenu = parentDropdown.querySelector('[data-dropdown-target="menu"]');
                if (dropdownMenu) {
                    dropdownMenu.classList.add('hidden');
                }
            }
        }

        const { reportableType, reportableId } = event.currentTarget.dataset
        this._showModal(reportableType, reportableId);
    }

    // New private helper method to handle showing the modal and setting values
    _showModal(reportableType, reportableId) {

        this.reportableTypeTarget.value = reportableType
        this.reportableIdTarget.value = reportableId
        this.reasonTarget.value = ""

        this.modalTarget.classList.remove("hidden")
        this.modalTarget.setAttribute("aria-hidden", "false")
        this.modalTarget.focus()
    }


    close() {
        this.modalTarget.classList.add("hidden")
        this.modalTarget.setAttribute("aria-hidden", "true")
    }

    handleEscape(event) {
        if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
            this.close()
        }
    }

    stopProp(event) {
        event.stopPropagation()
    }
}
