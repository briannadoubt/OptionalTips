import SwiftUI
import OptionalTips

@main @MainActor struct TipJarDemoApp: App {
    // These identifiers exist only in the checked-in local StoreKit fixture.
    // Replace them with your app's confirmed products before production use.
    @State private var tips = TipStore(configuration: .init(
        appName: "Demo",
        products: TipConfiguration.amountsUSD.map {
            .init(id: "local.test.optionaltips.usd\($0)", intendedUSD: $0)
        }
    ), listenForUpdates: !ProcessInfo.processInfo.arguments.contains("--testing"))
    @State private var showsTips = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 24) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 72)).foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("A little support, always optional")
                        .font(.title2).multilineTextAlignment(.center)
                    Text("This sample uses local StoreKit products. Its core screen remains available whether you tip or not.")
                        .foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Open tip jar") { showsTips = true }
                        .buttonStyle(.borderedProminent)
                }
                .padding(32).frame(maxWidth: 520)
                .navigationTitle("OptionalTips demo")
                .sheet(isPresented: $showsTips) { TipJarView(tips: tips) }
            }
        }
    }
}
