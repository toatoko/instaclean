// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "trigger"]
  static classes = ["hidden", "show"]

  connect() {
    // Close dropdown when clicking outside
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.boundCloseOnOutsideClick)

    // Ensure menu starts hidden
    this.close()
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    // Close other dropdowns first
    this.closeOtherDropdowns()

    // Toggle current dropdown
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove('hidden')
    this.menuTarget.classList.add('opacity-0', 'scale-95')

    // Force reflow
    this.menuTarget.offsetHeight

    // Add transition classes
    this.menuTarget.classList.add('transition', 'ease-out', 'duration-100')
    this.menuTarget.classList.remove('opacity-0', 'scale-95')
    this.menuTarget.classList.add('opacity-100', 'scale-100')

    // Update aria attributes
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', 'true')
    }
  }

  close() {
    if (!this.isOpen()) return

    this.menuTarget.classList.add('transition', 'ease-in', 'duration-75')
    this.menuTarget.classList.remove('opacity-100', 'scale-100')
    this.menuTarget.classList.add('opacity-0', 'scale-95')

    // Hide after animation
    setTimeout(() => {
      this.menuTarget.classList.add('hidden')
      this.menuTarget.classList.remove('transition', 'ease-in', 'duration-75', 'opacity-0', 'scale-95')
    }, 75)

    // Update aria attributes
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', 'false')
    }
  }

  isOpen() {
    return !this.menuTarget.classList.contains('hidden')
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOtherDropdowns() {
    document.querySelectorAll('[data-controller*="dropdown"]').forEach(dropdown => {
      if (dropdown !== this.element) {
        const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown')
        if (controller && controller.close) {
          controller.close()
        }
      }
    })
  }
}