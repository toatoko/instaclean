import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const savedTheme = localStorage.getItem('theme')
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

        if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
            this.enableDarkMode()
        } else {
            this.enableLightMode()
        }
    }

    toggle() {
        const isDark = document.body.classList.contains('dark')
        if (isDark) {
            this.enableLightMode()
        } else {
            this.enableDarkMode()
        }
    }

    enableDarkMode() {
        document.body.classList.add('dark')
        localStorage.setItem('theme', 'dark')
        this.updateNavigationColors(true)
        this.updateToggleButton('dark')
    }

    enableLightMode() {
        document.body.classList.remove('dark')
        localStorage.setItem('theme', 'light')
        this.updateNavigationColors(false)
        this.updateToggleButton('light')
    }

    updateNavigationColors(isDark) {
        // Optional: Set body bg color directly (overrides Tailwind)
        document.body.style.backgroundColor = isDark
            ? 'rgb(0 0 0)'           // black
            : 'rgb(245 245 245)'     // gray-100

        // Navbars
        const navElements = document.querySelectorAll('nav[data-theme-bg]')
        navElements.forEach(nav => {
            nav.style.backgroundColor = isDark
                ? 'rgb(0 0 0)'         // black
                : 'rgb(245 245 245)'   // gray-100

            nav.style.borderColor = isDark
                ? 'rgb(31 41 55)'      // gray-800
                : 'rgb(229 231 235)'   // gray-200
        })

        // Dropdowns
        const dropdownMenus = document.querySelectorAll('[data-dropdown-target="menu"]')
        dropdownMenus.forEach(menu => {
            menu.style.backgroundColor = isDark
                ? 'rgb(0 0 0)'
                : 'rgb(245 245 245)'

            menu.style.borderColor = isDark
                ? 'rgb(31 41 55)'
                : 'rgb(229 231 235)'
        })
    }

    updateToggleButton(theme) {
        const toggleButtons = document.querySelectorAll('[data-theme-toggle]')
        toggleButtons.forEach(button => {
            const sunIcon = button.querySelector('.fa-sun')
            const moonIcon = button.querySelector('.fa-moon')
            const text = button.querySelector('span')

            if (theme === 'dark') {
                sunIcon?.classList.remove('hidden')
                sunIcon?.classList.add('block')
                moonIcon?.classList.remove('block')
                moonIcon?.classList.add('hidden')
                if (text) text.textContent = 'Switch to light mode'
            } else {
                moonIcon?.classList.remove('hidden')
                moonIcon?.classList.add('block')
                sunIcon?.classList.remove('block')
                sunIcon?.classList.add('hidden')
                if (text) text.textContent = 'Switch to dark mode'
            }
        })
    }
}
