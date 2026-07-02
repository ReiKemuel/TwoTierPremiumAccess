# TwoTierPremiumAccess — Demo App

Reference SwiftUI shell exercising `PremiumAccessManager`. Not compiled as part of the library target.

To run:

1. In Xcode: `File > New > Project > iOS > App` (SwiftUI).
2. Add TwoTierPremiumAccess as a local Swift Package: `File > Add Package Dependencies > Add Local` → point at this repo's root.
3. Copy `TwoTierPremiumAccessDemoApp.swift` and `ContentView.swift` into your new project (delete the auto-generated `App.swift` and `ContentView.swift` first).
4. Build + run on any iOS 17+ simulator.

The demo has a "Grant unlock for 15 seconds" button — useful for eyeballing the expiry timer and the `showExpiryNotice` toggle without waiting an hour.
