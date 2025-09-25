import { Controller } from "@hotwired/stimulus";

// Conecta o formulário de CEP para validar o formato no frontend
export default class extends Controller {
  static targets = ["zip"];

  formatZip() {
    const digits = this.zipTarget.value.replace(/\D/g, "").slice(0, 9);

    if (digits.length === 0) {
      this.zipTarget.value = "";
      return;
    }

    if (digits.length <= 5) {
      this.zipTarget.value = digits;
      return;
    }

    const formatted = `${digits.slice(0, 5)}-${digits.slice(5)}`;
    this.zipTarget.value = formatted;
  }

  validate(event) {
    const rawValue = this.zipTarget.value.trim();
    const digitsOnly = rawValue.replace(/\D/g, "");

    this.clearFlash();

    if (digitsOnly.length === 0) {
      this.showFlash("alert", "Enter a ZIP code to check the forecast.");
      event.preventDefault();
      return;
    }

    if (!(digitsOnly.length === 5 || digitsOnly.length === 9)) {
      this.showFlash("alert", "Enter a valid US ZIP code (12345 or 12345-6789).");
      event.preventDefault();
      return;
    }

    if (!(rawValue.match(/^\d{5}$/) || rawValue.match(/^\d{5}-\d{4}$/))) {
      this.showFlash("alert", "Enter a valid US ZIP code (12345 or 12345-6789).");
      event.preventDefault();
    }
  }

  showFlash(type, message) {
    const container = this.flashContainer;
    if (!container) return;

    const flash = document.createElement("div");
    flash.classList.add("flash", type);
    flash.setAttribute("role", "alert");
    flash.textContent = message;

    container.appendChild(flash);
  }

  clearFlash() {
    const container = this.flashContainer;
    if (!container) return;

    container.innerHTML = "";
  }

  get flashContainer() {
    return document.querySelector(".flash-messages");
  }
}

