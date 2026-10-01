# Agent guide

This repository is a standalone Swift package, not an app release project.

- Keep all purchase behavior optional. Never introduce feature or gameplay gates.
- Preserve Swift 6 concurrency and minimum iOS17/macOS14/visionOS1/tvOS17 support.
- Match exact configured consumable IDs before finishing verified transactions.
  Never finish another feature's subscription/nonconsumable transactions.
- Display names/prices from StoreKit. Tier USD metadata is for disclosure only.
- Do not invent live product IDs, prices, purchases, App Store configuration,
  signing identities or publisher authorization. Example IDs are local fixtures.
- Keep one store alive outside presentation; avoid strong task/store retain cycles.
- Keep Done enabled. Test cancellation, load failure, pending and recovery paths.
- Package source must not depend on the example app, user projects or local paths.
- Keep English base strings in package localization resources; support host copy.
- Run `swift test`. For StoreKit changes also run the example's signed iOS test
  action; standalone SwiftPM skips the app-host session test.
- The generated example project is checked in. Update project.yml first and
  regenerate with XcodeGen when changing targets.
- Do not publish app source or private purchase/store evidence in this repo.
