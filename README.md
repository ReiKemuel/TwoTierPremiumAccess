# TwoTierPremiumAccess

A small Swift Package that shows the two-tier premium-access pattern I shipped in Ambio, a live App Store app. One user can be granted premium in two different ways — a temporary unlock from watching a rewarded ad, or a permanent unlock from a paid subscription — and the app needs a single reactive flag to gate features on either one.

The pattern here is a Combine `CombineLatest` pipeline that derives `hasPremiumAccess` from the two independent inputs, with a `UserDefaults`-persisted expiry timer for the ad-unlock side.

> Extracted from Ambio (live on the App Store since May 2026). The design here — the two-tier model and the Combine pipeline — is my work from a 2026-03-17 refactor. I've stripped the direct StoreKit coupling so this package doesn't depend on a specific subscription source. In Ambio, `isSubscribed` is written to by a StoreKit 2 sync that my teammate authored; here, it's a plain `@Published` field you write to yourself. **This is the pattern; wire your own subscription source in.**

---

## Requirements

- iOS 17+
- Xcode 15+
- Swift 5.9+
- No third-party dependencies (Foundation + Combine only)

## Install

Add the package to your project in Xcode:

`File > Add Package Dependencies…` → paste this repo's URL → `Add Package`.

Or edit your `Package.swift`:

```swift
.package(url: "https://github.com/ReiKemuel/TwoTierPremiumAccess.git", from: "1.0.0")
```

Then anywhere in your app:

```swift
import TwoTierPremiumAccess

// Read the derived flag
if PremiumAccessManager.shared.hasPremiumAccess {
    // gate your premium feature
}
```

See [`Examples/`](Examples/) for a working SwiftUI shell that flips both inputs live.

---

## The two-tier model

Two independent `@Published` inputs:

| Input | Source | Duration |
|---|---|---|
| `isAdUnlocked` | Set to `true` in `grantAdUnlock()`, expires after `unlockDuration` (default: 1 hour) | Temporary |
| `isSubscribed` | You set this from your subscription source of truth (StoreKit 2, RevenueCat, your backend) | Permanent |

One derived reactive flag:

```swift
@Published public private(set) var hasPremiumAccess: Bool = false
```

Wired via Combine at init:

```swift
private func setupPremiumAccessBinding() {
    Publishers.CombineLatest($isAdUnlocked, $isSubscribed)
        .map { $0 || $1 }
        .removeDuplicates()
        .assign(to: &$hasPremiumAccess)
}
```

`hasPremiumAccess` fires `true` the moment either input flips `true`, and stays `true` as long as either remains `true`. `removeDuplicates()` avoids re-publishing the same value when only one input changes but the OR result doesn't move.

Views subscribe to `PremiumAccessManager.shared` as an `@ObservedObject` (or `@StateObject` at the top of your view tree) and read `hasPremiumAccess`. When either input flips, dependent UI updates automatically.

---

## The ad-unlock lifecycle

Rewarded ad succeeds → your ad manager calls:

```swift
PremiumAccessManager.shared.grantAdUnlock()
```

Which does five things in sequence:

```swift
public func grantAdUnlock() {
    let expiry = Date().addingTimeInterval(unlockDuration)
    adUnlockExpiry = expiry           // publish the new expiry date
    isAdUnlocked = true               // flip the input — CombineLatest fires
    showExpiryNotice = false          // dismiss any leftover expiry toast
    persistExpiry(expiry)             // survive app-kill
    scheduleExpiryTimer(at: expiry)   // fire when unlock expires
}
```

**Persistence.** The expiry date is stored as a `TimeInterval` in `UserDefaults`:

```swift
UserDefaults.standard.set(date.timeIntervalSince1970, forKey: expiryKey)
```

On next launch, `restoreStateFromDefaults()` reads it back — if it's still in the future, we restore `isAdUnlocked = true` and reschedule the timer; if it's past, we clear it and set `showExpiryNotice = true` so the app can show the user their unlock ran out while they were away.

**The timer.** `scheduleExpiryTimer(at:)` cancels any previous timer and fires exactly once when the unlock expires:

```swift
expiryTimer = Timer.publish(every: remaining, on: .main, in: .common)
    .autoconnect()
    .first()
    .sink { [weak self] _ in
        guard let self else { return }
        self.isAdUnlocked = false
        self.adUnlockExpiry = nil
        self.showExpiryNotice = true
        self.clearExpiry()
    }
```

When the timer fires, `isAdUnlocked` flips back to `false`, the CombineLatest pipeline re-evaluates, and `hasPremiumAccess` becomes whatever `isSubscribed` is. Users who watched a rewarded ad and never subscribed will see gates snap back into place; users who subscribed during the unlock window keep access seamlessly.

---

## Honest notes

**`Timer.publish` for the expiry timer isn't the right primitive.** It works, but Swift Concurrency's `Task { try await Task.sleep(...) }` is cancellation-safe and composes better with the rest of a modern app. This is on my own refactor list — it's small and I'll ship it in Ambio when I next touch this file.

**`showExpiryNotice` is an event disguised as state.** A `Bool` you flip to `true` when something happens and then flip back to `false` after the UI has acknowledged it is really a one-shot event. The right shape is `PassthroughSubject<Void, Never>`. I kept the `Bool` because the app-side listener (an `.onReceive` overlay in `ContentView`) already works, and the migration touches every listener. Also on my refactor list.

**`isSubscribed` here is a plain settable field.** In Ambio, my teammate wired StoreKit 2 into a `syncWithStoreKit()` method that writes to it, and gated writes as `private(set)`. Extracting that would drag StoreKit into a sample that doesn't need it. Here you write to it yourself — from your `StoreManager`, a webhook-backed backend flag, RevenueCat's `hasActiveSubscription`, or a mock in your previews.

The line `@Published public var isSubscribed: Bool = false` is where you plug in.

---

## About

Written by me, [Rei Kemuel Cordero](https://github.com/ReiKemuel), on Ambio. The Combine pipeline is exactly what ships in production. The framing and refactor notes come from actually maintaining this thing.

If you'd design it differently — protocol-oriented subscription source, actor-based expiry, ditch the singleton — open an issue. I'm always up for a good design conversation.

MIT licensed.
