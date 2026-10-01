import SwiftUI
import StoreKit
import Accessibility

public struct TipJarView: View {
    let tips: TipStore
    public init(tips: TipStore) { self.tips = tips }
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss
    @State private var showsMore = false

    public var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "Support \(tips.configuration.appName)", bundle: .module)) {
                    Text(tips.configuration.explanation)
                    Text(String(localized: "Each tip is a single purchase. You can tip again whenever you like.", bundle: .module))
                        .font(.callout).foregroundStyle(.secondary)
                    if tips.isLoading { ProgressView(String(localized: "Loading tips…", bundle: .module)) }
                    ForEach(showsMore ? tips.products : tips.featuredProducts) { product in
                        Button {
                            Task { await tips.purchase(product, using: { try await purchase($0) }) }
                        } label: {
                            HStack {
                                Text(product.displayName).fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Text(product.displayPrice).fixedSize()
                            }
                        }
                        .disabled(tips.isPurchasing || !AppStore.canMakePayments)
                        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
                    }
                    if tips.products.contains(where: { !tips.featuredProducts.map(\.id).contains($0.id) }) {
                        Button(showsMore ? String(localized: "Fewer amounts", bundle: .module) : String(localized: "More amounts", bundle: .module)) { showsMore.toggle() }
                    }
                    if tips.isPurchasing { ProgressView(String(localized: "Completing tip…", bundle: .module)) }
                    if !AppStore.canMakePayments {
                        Text(String(localized: "Purchases are disabled on this device. You can keep using \(tips.configuration.appName).", bundle: .module))
                    }
                    if let message = tips.message {
                        Text(message).accessibilityIdentifier("tip-status")
                    }
                    if !tips.productIDs.isEmpty, !tips.isLoading {
                        Button(String(localized: "Reload tips", bundle: .module)) { Task { await tips.load() } }.disabled(tips.isPurchasing)
                    }
                }
                Text(String(localized: "Tips are optional and do not unlock features.", bundle: .module))
            }
            .navigationTitle(String(localized: "Tip jar", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done", bundle: .module)) { dismiss() }
                }
            }
            .task { await tips.load() }
            .onChange(of: tips.message) { _, message in
                if let message { AccessibilityNotification.Announcement(message).post() }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, idealWidth: 460, minHeight: 360, idealHeight: 520)
        #endif
    }
}
