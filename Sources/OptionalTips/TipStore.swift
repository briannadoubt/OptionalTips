import Foundation
import Observation
import StoreKit

@MainActor @Observable public final class TipStore {
    public let configuration: TipConfiguration
    public let productIDs: [String]
    public private(set) var products: [Product] = []
    public private(set) var isLoading = false
    public private(set) var isPurchasing = false
    public private(set) var message: String?
    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private var handled: Set<UInt64> = []

    public init(configuration: TipConfiguration, listenForUpdates: Bool = true) {
        self.configuration = configuration
        let productIDs = configuration.products.map(\.id)
        self.productIDs = Array(Set(productIDs)).sorted()
        guard listenForUpdates, !productIDs.isEmpty else { return }
        updatesTask = Task { [weak self] in
            // Start listening before recovering unfinished purchases. Both paths
            // share verification, product matching, deduplication and finishing.
            let recovery = Task { [weak self] in
                for await result in Transaction.unfinished {
                    await self?.receive(result)
                }
            }
            defer { recovery.cancel() }
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
                await self?.receive(result)
            }
        }
    }
    deinit { updatesTask?.cancel() }

    public func load(using action: ([String]) async throws -> [Product] = { try await Product.products(for: $0) }) async {
        guard !isLoading else { return }
        guard !productIDs.isEmpty else {
            message = String(localized: "Tips are not available yet. You can keep using \(configuration.appName).", bundle: .module)
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await action(productIDs)
            try Task.checkCancellation()
            products = loaded.filter { $0.type == .consumable && productIDs.contains($0.id) }.sorted {
                $0.price == $1.price ? $0.id < $1.id : $0.price < $1.price
            }
            message = products.isEmpty ? String(localized: "Tips are unavailable right now. You can keep using \(configuration.appName).", bundle: .module) : nil
        } catch is CancellationError { } catch {
            message = String(localized: "Could not load tips. Please try again.", bundle: .module)
        }
    }

    public func purchase(_ product: Product, using action: @MainActor (Product) async throws -> Product.PurchaseResult) async {
        guard !isPurchasing, productIDs.contains(product.id), product.type == .consumable else { return }
        guard AppStore.canMakePayments else {
            message = String(localized: "Purchases are disabled on this device. You can keep using \(configuration.appName).", bundle: .module)
            return
        }
        isPurchasing = true
        message = nil
        defer { isPurchasing = false }
        do {
            switch try await action(product) {
            case .success(let result): await receive(result)
            case .pending: message = String(localized: "Your tip is awaiting approval. You can keep using \(configuration.appName).", bundle: .module)
            case .userCancelled: break
            @unknown default: message = String(localized: "The tip could not be completed. Please try again.", bundle: .module)
            }
        } catch is CancellationError { } catch {
            message = String(localized: "The tip could not be completed. Please try again.", bundle: .module)
        }
    }

    private func receive(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard productIDs.contains(transaction.productID), transaction.productType == .consumable else { return }
            // A revoked tip never earns a thank-you and has no gameplay effect.
            let first = handled.insert(transaction.id).inserted
            await transaction.finish()
            if first, transaction.revocationDate == nil { message = String(localized: "Thank you for supporting \(configuration.appName)!", bundle: .module) }
        case .unverified(let transaction, _):
            guard productIDs.contains(transaction.productID) else { return }
            message = String(localized: "The tip could not be verified. Please contact Apple Support.", bundle: .module)
        }
    }
}
