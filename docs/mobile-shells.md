# Centime mobile shells (Hotwire Native)

Two thin native apps wrap the Rails app. They live in separate repos
(`centime-ios`, `centime-android`) and stay under ~500 lines each: navigation,
tabs, and bridge components come from Hotwire Native; all screens are the
Rails app itself.

The Rails side is already done (this repo):

- Path configuration endpoints (no auth):
  - `GET /hotwire_native/v1/ios/path_configuration`
  - `GET /hotwire_native/v1/android/path_configuration`
- Web chrome (nav bar) is hidden for native user agents (`turbo_native_app?`).
- Bridge Stimulus controllers registered under `app/javascript/controllers/bridge/`
  (button, form, menu, nav, overflow menu, review prompt).
- Devise cookie sessions work in the shells' webviews as-is.

## Tabs (both platforms)

| Tab | Root URL |
|---|---|
| Dashboard | `/` |
| Transactions | `/transactions` |
| Reports | `/reports` |
| Banks | `/bank_connections` |

## iOS (`centime-ios`)

1. Xcode → new iOS App (SwiftUI or UIKit), min iOS 16.
2. Add the Swift package: `https://github.com/hotwired/hotwire-native-ios`.
3. `HotwireTabBarController` with the four tabs above; each tab gets a
   `Navigator` rooted at its URL.
4. Load the remote path configuration:
   ```swift
   Hotwire.loadPathConfiguration(from: [
     .server(URL(string: "https://<host>/hotwire_native/v1/ios/path_configuration")!)
   ])
   Hotwire.config.applicationUserAgentPrefix = "Centime iOS"
   ```
5. Register bridge components: `Hotwire.registerBridgeComponents([ButtonComponent.self, FormComponent.self, ...])`.
6. External URLs (GoCardless bank consent, Stripe Checkout) are opened via
   `SFSafariViewController` by the default external-URL handler — do not
   override this; PSD2/Stripe forbid embedded webview flows.
7. Universal link for `/bank_connections/callback` so the consent flow returns
   to the app (associated domains + `apple-app-site-association` on the host).

## Android (`centime-android`)

1. Android Studio → Empty Views Activity, min SDK 28, Kotlin.
2. Dependency: `implementation("dev.hotwire:navigation-fragments:<latest>")`
   (hotwire-native-android).
3. `HotwireActivity` + bottom navigation with four `HotwireNavigation`
   destinations rooted at the tab URLs.
4. Path configuration:
   ```kotlin
   Hotwire.loadPathConfiguration(
     context = this,
     location = PathConfiguration.Location(
       remoteFileUrl = "https://<host>/hotwire_native/v1/android/path_configuration"
     )
   )
   Hotwire.config.applicationUserAgentPrefix = "Centime Android"
   ```
5. Register the matching bridge components.
6. External URLs open in Custom Tabs by default — keep it for bank/Stripe.
7. App Link (`assetlinks.json` on the host) for `/bank_connections/callback`.

## Store risks / lead times

- Apple 4.2 "minimum functionality": native tabs, modals via path config, and
  bridge components are the mitigation. Budget one rejection cycle.
- Google Play: new personal accounts need a 14-day closed test with 12+
  testers before production — start that clock as early as possible.
