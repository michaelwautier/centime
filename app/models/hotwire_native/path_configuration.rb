module HotwireNative
  # Server-driven navigation rules for the iOS and Android shells.
  # https://native.hotwired.dev/reference/path-configuration
  module PathConfiguration
    module_function

    def rules(platform:)
      {
        settings: {},
        rules: [
          # Forms open as native modals.
          {
            patterns: [ "/new$", "/edit$" ],
            properties: { context: "modal", pull_to_refresh_enabled: false }
          },
          # Devise screens: modal, no pull-to-refresh.
          {
            patterns: [ "^/users/" ],
            properties: { context: "modal", pull_to_refresh_enabled: false }
          },
          # Main tabs refresh with pull-to-refresh and replace the root.
          # External domains (bank consent, Stripe Checkout) are opened in the
          # system browser by the shells' default external-URL handling.
          {
            patterns: [ "^/$", "^/dashboard$", "^/transactions$", "^/reports$", "^/bank_connections$" ],
            properties: { presentation: "replace_root", pull_to_refresh_enabled: true }
          }
        ]
      }
    end
  end
end
