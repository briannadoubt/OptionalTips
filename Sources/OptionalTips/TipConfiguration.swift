import Foundation
import StoreKit

/// USD amounts describe the desired tier, never a displayed or charged price.
public struct TipProductDefinition: Sendable, Equatable {
    public let id: String
    public let intendedUSD: Int
    public init(id: String, intendedUSD: Int) { self.id = id; self.intendedUSD = intendedUSD }
}
public struct TipConfiguration: Sendable {
    public static let amountsUSD = [1, 3, 5, 10, 20, 50, 100]
    public static let featuredUSD = [5, 10, 20]
    public let appName: String
    public let explanation: String
    public let featuredAmountsUSD: [Int]
    public let products: [TipProductDefinition]
    public var featuredIDs: [String] {
        products.filter { featuredAmountsUSD.contains($0.intendedUSD) }.sorted { $0.intendedUSD < $1.intendedUSD }.map(\.id)
    }
    public init(appName: String, explanation: String? = nil, products: [TipProductDefinition], featuredAmountsUSD: [Int] = Self.featuredUSD) {
        self.featuredAmountsUSD = Array(Set(featuredAmountsUSD)).sorted()
        self.appName = appName
        self.explanation = explanation ?? String(localized: "Optional tips support development and do not unlock any features.", bundle: .module)
        var seen: Set<String> = []
        self.products = products.filter { !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && seen.insert($0.id).inserted }
    }
}
extension TipStore {
    public var featuredProducts: [Product] {
        configuration.featuredIDs.compactMap { id in products.first { $0.id == id } }
    }
}
