# Integrating OptionalTips

1. Add the versioned Swift package and link its `OptionalTips` product.
2. Confirm consumable products for **your own app** in App Store Connect. Product
   identifiers are exact, app-specific configuration; do not copy another app's
   identifiers or confuse the local fixture with live products.
3. Supply `[TipProductDefinition]` to `TipConfiguration`. The intended USD scale
   is 1/3/5/10/20/50/100 and featured amounts are 5/10/20. App Store Connect owns
   actual pricing, regions, localized names/descriptions, availability, and review
   information. Regional prices can differ from intended USD metadata.
4. Own one `TipStore` for the app lifecycle. Present `TipJarView(tips:)` from an
   explicitly chosen support action. If your app uses a custom game input loop,
   pause or gate that input while its own menu is open.
5. Test unavailable, restricted-payment, cancellation, error, pending, and
   verified-purchase states with your own app host. Then validate with a signed
   Apple sandbox build before release. Local tests do not prove store readiness.

The package does not create products, set prices, accept agreements, submit apps,
restore entitlements, or contact a developer purchase server. Every tip is an
independent consumable purchase. It never awards an entitlement or unlock.

## Custom presentation

`TipStore` exposes read-only `products`, `isLoading`, `isPurchasing`, `message`,
`configuration`, `productIDs`, and `featuredProducts` through Observation.
You can build your own view without adopting the included sheet:

```swift
await tips.load()
await tips.purchase(product, using: { try await purchase($0) })
```

Obtain `purchase` from SwiftUI's `@Environment(\.purchase)` so StoreKit uses the
correct presentation context. Never call purchase automatically on load.
The store rejects concurrent purchases, unknown IDs, nonconsumables and disabled
payments. `load(using:)` is injectable for deterministic load-error tests.

## Local example tests

The example schemes select `Tests/OptionalTipsTests/LocalTips.storekit` for run
sessions. Its iOS app test target includes the same test source/resource and
creates `SKTestSession` before loading products. Standalone SwiftPM tests skip
the session test because they have no app host. The demo suppresses its own
transaction listener while XCTest is hosting tests to avoid consuming test
transactions through a second store.

Read Apple's [in-app purchase overview](https://developer.apple.com/in-app-purchase/)
and [StoreKit documentation](https://developer.apple.com/documentation/storekit)
for the platform's current setup and review requirements.
