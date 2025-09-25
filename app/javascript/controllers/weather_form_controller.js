import { Controller } from "@hotwired/stimulus";

// Conecta o formulário de CEP para validar o formato no frontend
export default class extends Controller {
  static targets = ["zip", "city"];

  connect() {
    this.toggleInputs();
  }

  onInput() {
    this.toggleInputs();
  }

  formatZip() {
    if (!this.hasZipTarget) return;

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
    const rawZip = this.hasZipTarget ? this.zipTarget.value.trim() : "";
    const digitsOnly = rawZip.replace(/\D/g, "");
    const rawCity = this.hasCityTarget ? this.cityTarget.value.trim() : "";

    this.clearFlash();

    this.toggleInputs();

    if (digitsOnly.length === 0 && rawCity === "") {
      this.showFlash("alert", "Enter a ZIP code or city to check the forecast.");
      event.preventDefault();
      return;
    }

    if (digitsOnly.length > 0) {
      if (!(digitsOnly.length === 5 || digitsOnly.length === 9)) {
        this.showFlash("alert", "Enter a valid US ZIP code (12345 or 12345-6789).");
        event.preventDefault();
        return;
      }

      if (!(rawZip.match(/^\d{5}$/) || rawZip.match(/^\d{5}-\d{4}$/))) {
        this.showFlash("alert", "Enter a valid US ZIP code (12345 or 12345-6789).");
        event.preventDefault();
      }
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

  toggleInputs() {
    if (!this.hasZipTarget || !this.hasCityTarget) return;

    const hasZip = this.zipTarget.value.trim().length > 0;
    const hasCity = this.cityTarget.value.trim().length > 0;

    if (hasZip && !hasCity) {
      this.cityTarget.setAttribute("disabled", "disabled");
    } else {
      this.cityTarget.removeAttribute("disabled");
    }

    if (hasCity && !hasZip) {
      this.zipTarget.setAttribute("disabled", "disabled");
    } else {
      this.zipTarget.removeAttribute("disabled");
    }
  }
}

