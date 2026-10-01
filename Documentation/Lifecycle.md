# Lifecycle and transaction ownership

`TipStore` is a main-actor Observable object. Keep one instance alive at the app
composition root; multiple windows should share it to serialize purchases.
The included sheet owns presentation state, not transaction ownership.

When configured, the store listens to `Transaction.updates` and recovers
`Transaction.unfinished`. Both routes use the same verification, product/type
matching, in-memory deduplication, and finishing path. The listener captures the
store weakly and is cancelled when the store is destroyed. Closing the tip sheet
does not cancel the app-owned listener or leave pending purchases dependent on
that sheet remaining visible.

Only verified transactions matching configured **consumable** IDs are finished.
Other IAPs in your app, including subscriptions and feature unlocks, are ignored.
Do not put those identifiers in tip configuration. Unverified transactions are
not finished. Revoked tips produce no thank-you and have no entitlement effect.

A cancelled purchase is quiet. A pending purchase explains approval is needed;
the person can continue using the app. Failure and verification errors produce
recoverable messages. Product-load cancellation releases loading state without
inventing a successful result. Loaded products can be retried from the sheet.

Deduplication lasts only for that store instance. No entitlement or lifetime-tip
ledger is stored. A recovered transaction can produce a thank-you after restart;
no user feature depends on whether that notification was displayed.

## Privacy

The source contains no analytics, advertising, third-party SDK, explicit network
client, purchase server, or persistent transaction database. StoreKit communicates
with Apple as part of the platform purchase flow. Transaction identifiers used
for notification deduplication remain in memory. Product metadata is supplied by
the host app and StoreKit. Your app remains responsible for its own privacy
information, payment configuration, and any other SDKs it uses.
