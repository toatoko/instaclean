import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu"]

    toggle(event) {
        event.preventDefault()
        if (this.menuTarget.classList.contains("hidden")) {
            this.menuTarget.classList.remove("hidden")
            this.menuTarget.classList.add("flex")
        } else {
            this.menuTarget.classList.add("hidden")
            this.menuTarget.classList.remove("flex")
        }
    }
}
