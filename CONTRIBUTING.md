# Contributing

Keep the package small: optional consumable tips, accessible native presentation,
and reliable StoreKit lifecycle handling. Do not add a paywall, entitlement
system, analytics, purchase backend, or app-specific product definitions.

Use Swift 6 and supported Apple SDKs. Run `swift test` and the example's iOS test
action for transaction changes. For UI changes, check narrow windows and Dynamic
Type, verify Done remains reachable, and use local fixture products only. Explain
what you tested and which platforms you did not exercise in your pull request.

Localization contributions go in `Sources/OptionalTips/Resources/<locale>.lproj`.
Keep format placeholders consistent and translate all keys. App-supplied copy
remains the host app's responsibility.

See [LICENSE](LICENSE) for contribution terms.
