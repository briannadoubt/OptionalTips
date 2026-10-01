import Foundation
import Testing
import StoreKit
import StoreKitTest
@testable import OptionalTips

@Suite(.serialized) struct TipTests {
    @Test func configurationUsesApprovedAmountsAndRemovesInvalidIDs() {
        #expect(TipConfiguration.amountsUSD == [1,3,5,10,20,50,100])
        #expect(TipConfiguration.featuredUSD == [5,10,20])
        let config = TipConfiguration(appName: "Test", products: [
            .init(id: "", intendedUSD: 5), .init(id: "same", intendedUSD: 5), .init(id: "same", intendedUSD: 10)
        ])
        #expect(config.products.count == 1)
        #expect(config.featuredIDs == ["same"])
        let custom = TipConfiguration(appName: "Test", products: [.init(id: "three", intendedUSD: 3)], featuredAmountsUSD: [3,3])
        #expect(custom.featuredIDs == ["three"])
        #expect(custom.featuredAmountsUSD == [3])
    }
    @Test @MainActor func emptyConfigurationNeverRequestsPurchases() async {
        let store = TipStore(configuration: .init(appName: "Test", products: []))
        await store.load()
        #expect(store.products.isEmpty)
        #expect(store.message == "Tips are not available yet. You can keep using Test.")
        #expect(!store.isLoading && !store.isPurchasing)
    }
    @Test @MainActor func loadingFailureAndCancellationReleaseLoadingState() async {
        let store = TipStore(configuration: .init(appName: "Test", products: [.init(id: "local.test.five", intendedUSD: 5)]), listenForUpdates: false)
        struct LoadFailure: Error {}
        await store.load(using: { _ in throw LoadFailure() })
        #expect(store.message == "Could not load tips. Please try again.")
        #expect(!store.isLoading)
        await store.load(using: { _ in throw CancellationError() })
        #expect(!store.isLoading)
        await store.load(using: { _ in [] })
        #expect(store.message == "Tips are unavailable right now. You can keep using Test.")
        #expect(!store.isLoading)
    }
    // Real local StoreKit needs an app test host. An app integration test target
    // runs this same source; standalone SwiftPM tests have no app dependency.
    #if !SWIFT_PACKAGE
    @Test(.timeLimit(.minutes(3))) @MainActor func localStoreKitPurchasesAndRecoverableOutcomes() async throws {
        #if SWIFT_PACKAGE
        let url = try #require(Bundle.module.url(forResource: "LocalTips", withExtension: "storekit"))
        #else
        let url = try #require(Bundle(for: TipTestBundle.self).url(forResource: "LocalTips", withExtension: "storekit"))
        #endif
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        let config = TipConfiguration(appName: "Test", products: TipConfiguration.amountsUSD.map {
            .init(id: "local.test.optionaltips.usd\($0)", intendedUSD: $0)
        })
        let store = TipStore(configuration: config)
        await store.load()
        #expect(store.products.count == 7)
        #expect(store.featuredProducts.map(\.price) == [Decimal(5),Decimal(10),Decimal(20)])
        let product = try #require(store.products.first)
        await store.purchase(product, using: { _ in .userCancelled })
        #expect(store.message == nil && !store.isPurchasing)
        struct PurchaseFailure: Error {}
        await store.purchase(product, using: { _ in throw PurchaseFailure() })
        #expect(store.message == "The tip could not be completed. Please try again.")
        await store.purchase(product, using: { _ in throw CancellationError() })
        #expect(store.message == nil && !store.isPurchasing)
        await store.purchase(product, using: { _ in .pending })
        #expect(store.message == "Your tip is awaiting approval. You can keep using Test.")
        await store.purchase(product, using: { try await $0.purchase() })
        #expect(store.message == "Thank you for supporting Test!")
        #expect(!store.isPurchasing)
        #expect(session.allTransactions().count == 1)
        // Repeatable tips, no entitlement or feature dependency.
        await store.purchase(product, using: { try await $0.purchase() })
        #expect(session.allTransactions().count == 2)
        session.askToBuyEnabled = true
        let pendingProduct = try #require(store.products.first { $0.price == Decimal(5) })
        await store.purchase(pendingProduct, using: { try await $0.purchase() })
        #expect(store.message == "Your tip is awaiting approval. You can keep using Test.")
        #expect(!store.isPurchasing)
    }
    @Test(.timeLimit(.minutes(3))) @MainActor func unrelatedAndUnverifiedTransactionsAreNotFinished() async throws {
        let url = try #require(Bundle(for: TipTestBundle.self).url(forResource: "LocalTips", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        let store = TipStore(configuration: .init(appName: "Test", products: [.init(id: "local.test.optionaltips.usd5", intendedUSD: 5)]), listenForUpdates: false)
        await store.load()
        var finishCalls = 0
        store.finishTransaction = { _ in finishCalls += 1 }
        let own = try #require(store.products.first)
        let foreign = try #require(try await Product.products(for: ["local.test.unrelated"]).first)
        let foreignResult = try await foreign.purchase()
        guard case .success(.verified(let foreignTransaction)) = foreignResult else {
            Issue.record("Expected a verified local foreign fixture transaction")
            return
        }
        await store.purchase(own, using: { _ in foreignResult })
        #expect(store.message == nil)
        let ownResult = try await own.purchase()
        guard case .success(.verified(let ownTransaction)) = ownResult else {
            Issue.record("Expected a verified local tip fixture transaction")
            return
        }
        await store.purchase(own, using: { _ in .success(.unverified(ownTransaction, .invalidSignature)) })
        #expect(store.message == "The tip could not be verified. Please contact Apple Support.")
        #expect(finishCalls == 0)
        await store.purchase(own, using: { _ in .success(.verified(ownTransaction)) })
        #expect(finishCalls == 1)
        // Test cleanup is explicit; the library did not finish either result.
        await foreignTransaction.finish()
        await ownTransaction.finish()
    }
    #endif
}
#if !SWIFT_PACKAGE
private final class TipTestBundle: NSObject {}
#endif
