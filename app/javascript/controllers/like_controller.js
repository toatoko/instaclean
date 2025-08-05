import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["heart"]

    connect() {
        this.element.addEventListener("turbo:submit-end", (event) => {
            if (event.detail.success) {
                this.heartTarget.classList.add("like-animation")
                setTimeout(() => {
                    this.heartTarget.classList.remove("like-animation")
                }, 300)
            }
        })
    }
}