import { Controller } from "@hotwired/stimulus"

// Submits the surrounding form when an input changes (inline category select).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
