import SwiftUI

struct RemoveAdsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var monetization: MonetizationStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.93, blue: 0.78),
                        Color(red: 0.86, green: 0.97, blue: 0.94),
                        Color(red: 1.00, green: 0.88, blue: 0.93)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image("GomokuMascots")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 82)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 6) {
                            Label(
                                monetization.adsRemoved ? "廣告已移除" : "移除廣告",
                                systemImage: monetization.adsRemoved ? "checkmark.seal.fill" : "rectangle.slash"
                            )
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(StoreTheme.ink)

                            Text("讓棋盤更乾淨")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(StoreTheme.berry)
                        }
                    }

                    if let message = monetization.purchaseState.message {
                        Text(message)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(StoreTheme.ink.opacity(0.68))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(StoreTheme.berry)
                            .frame(width: 22)
                        Text("購買與使用受 Apple 標準 EULA 及本 App 隱私聲明約束。請由家長操作購買。")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(StoreTheme.ink.opacity(0.64))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer(minLength: 0)

                    Button {
                        monetization.purchaseRemoveAds()
                    } label: {
                        if monetization.purchaseState == .loading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(monetization.adsRemoved ? "已啟用" : "購買移除廣告")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(StorePrimaryButtonStyle())
                    .disabled(monetization.adsRemoved || monetization.purchaseState == .loading)

                    Button {
                        monetization.restorePurchases()
                    } label: {
                        Text("恢復購買")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(StoreSecondaryButtonStyle())
                    .disabled(monetization.purchaseState == .loading)
                }
                .padding(22)
            }
            .navigationTitle("商店")
            .inlineNavigationTitle()
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem {
                    Button("完成") {
                        dismiss()
                    }
                }
                #endif
            }
        }
        .onAppear {
            monetization.refreshCustomerInfo()
        }
    }
}

private enum StoreTheme {
    static let ink = Color(red: 0.18, green: 0.17, blue: 0.30)
    static let berry = Color(red: 0.91, green: 0.25, blue: 0.48)
    static let coral = Color(red: 1.00, green: 0.48, blue: 0.36)
}

private struct StorePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [StoreTheme.berry, StoreTheme.coral], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

private struct StoreSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(StoreTheme.berry)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule(style: .continuous).fill(.white.opacity(0.86)))
            .overlay(Capsule(style: .continuous).stroke(StoreTheme.berry.opacity(0.22), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

private extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
