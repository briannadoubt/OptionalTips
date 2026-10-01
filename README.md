# OptionalTips

A small, native tip jar for SwiftUI. Support stays optional. Your app stays yours.

**StoreKit 2 · Swift 6 · SwiftUI · MIT**

[![Swift and StoreKit](https://github.com/briannadoubt/OptionalTips/actions/workflows/ci.yml/badge.svg)](https://github.com/briannadoubt/OptionalTips/actions/workflows/ci.yml)

OptionalTips gives you a ready-to-present sheet, localized StoreKit prices,
repeatable consumable purchases, and transaction recovery. It has no paywall,
entitlements, analytics, backend, or third-party dependencies.

## Add the package

In Xcode, choose **File → Add Package Dependencies** and enter:

```
https://github.com/briannadoubt/OptionalTips
```

Or add it to your package manifest:

```swift
.package(url: "https://github.com/briannadoubt/OptionalTips.git", from: "0.1.1")
```

Add the `OptionalTips` product to your app target.

| Platform | Minimum |
| --- | --- |
| iOS / iPadOS | 17 |
| macOS | 14 |
| visionOS | 1 |
| tvOS | 17 |

These are compile-time minimums, not a claim of physical-device testing on every
OS release. The example supports iPhone, iPad, and Mac.

## Present a tip jar

Keep one store at your app's composition root. Present the sheet only when the
person chooses to support you.

```swift
import SwiftUI
import OptionalTips

struct SupportView: View {
    @State private var showingTips = false
    @State private var tips = TipStore(configuration: .init(
        appName: "My App",
        explanation: "Optional tips support development. All features stay available.",
        products: [
            // Replace these examples with your app's confirmed consumable IDs.
            .init(id: "your.app.tip.five", intendedUSD: 5),
            .init(id: "your.app.tip.ten", intendedUSD: 10),
            .init(id: "your.app.tip.twenty", intendedUSD: 20)
        ]
    ))

    var body: some View {
        Button("Support My App") { showingTips = true }
            .sheet(isPresented: $showingTips) {
                TipJarView(tips: tips)
            }
    }
}
```

For apps with multiple windows, own the store at the `App` level and pass the
same instance to each support view. Do not create it inside the sheet or gate
features on purchase state.

## Amounts and disclosure

The default intended USD scale is **1, 3, 5, 10, 20, 50, 100**. The sheet initially
shows configured **5, 10, and 20** tiers. **More amounts** shows every available
configured product once. No amount is selected automatically. Apps can override the featured grouping with
`featuredAmountsUSD` in configuration.

`intendedUSD` controls this grouping; it never determines a charged or displayed
price. Every product name and price comes from StoreKit's `displayName` and
`displayPrice`, including the person's currency and storefront. Unavailable or
nonconsumable products are omitted. An empty configuration is valid and displays
an unavailable message without starting the transaction listener.

The sheet adapts to platform navigation, supports Dynamic Type and VoiceOver
labels, announces status changes, and leaves **Done** available during purchase
and pending states. It has no custom animations to distract from the host app.

## Try the example

Open [TipJarDemo.xcodeproj](Examples/TipJarDemo/TipJarDemo.xcodeproj), select the
iOS or macOS demo scheme, and run. Both schemes reference the checked-in local
StoreKit configuration. The `local.test.*` products are fixtures, not live IDs.

The source of truth for the demo project is
[project.yml](Examples/TipJarDemo/project.yml). Regenerate it with XcodeGen if
you change targets; XcodeGen is not needed just to open or build the example.

## Tests

```sh
swift test
```

Standalone tests cover configuration, unavailable products, load errors, and
cancellation. StoreKit session tests need a signed app host; run the demo's iOS
test action to verify local product loading, featured tiers, verified repeatable
purchases, purchase errors/cancellation, Ask to Buy pending, and ownership
isolation for unrelated/unverified transactions. These are local
simulated transactions, never proof of a production purchase.

CI runs standalone tests, the Mac example build, and signed local iOS StoreKit
tests on standard GitHub-hosted macOS runners, including an Intel simulator host. A separate host app is responsible
for its own UI regression and actual sandbox verification.

## Developer and agent guides

- [Integration and store configuration](Documentation/Integration.md)
- [Lifecycle, transaction ownership, and privacy](Documentation/Lifecycle.md)
- [Contributing](CONTRIBUTING.md)
- [Agent instructions](AGENTS.md)

English is the current bundled translation. Package strings use the package's
localization bundle; app names and explanatory copy are supplied by your app.
Add translations through `Resources/<language>.lproj/Localizable.strings`.

Licensed under [MIT](LICENSE). Issues and small, tested contributions are welcome.
