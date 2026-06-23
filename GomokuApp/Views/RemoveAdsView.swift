import SwiftUI

struct RemoveAdsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var monetization: MonetizationStore
    @State private var parentGateAction: ParentGateAction?
    @State private var parentGateChallenge = ParentGateChallenge.make()
    @State private var parentGateAnswer = ""
    @State private var parentGateMessage: String?

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
                        Text("購買與使用受 Apple 標準 EULA 及本 App 隱私聲明約束。購買與恢復購買前會先通過親子鎖。")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(StoreTheme.ink.opacity(0.64))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer(minLength: 0)

                    Button {
                        requestParentGate(for: .purchase)
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
                        requestParentGate(for: .restore)
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
        .sheet(item: $parentGateAction) { action in
            parentGateSheet(for: action)
                .presentationDetents([.height(360), .medium])
        }
    }

    private func requestParentGate(for action: ParentGateAction) {
        parentGateChallenge = ParentGateChallenge.make()
        parentGateAnswer = ""
        parentGateMessage = nil
        parentGateAction = action
    }

    private func submitParentGate(for action: ParentGateAction) {
        let normalizedAnswer = parentGateAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedAnswer == parentGateChallenge.answer else {
            parentGateMessage = "爸爸媽媽加油！！請再試一次吧！！"
            parentGateChallenge = ParentGateChallenge.make()
            parentGateAnswer = ""
            return
        }

        parentGateAction = nil
        parentGateAnswer = ""
        parentGateMessage = nil

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            switch action {
            case .purchase:
                monetization.purchaseRemoveAds()
            case .restore:
                monetization.restorePurchases()
            }
        }
    }

    private func parentGateSheet(for action: ParentGateAction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(StoreTheme.berry)

                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(StoreTheme.ink)
                    Text("請由家長完成下面的親子鎖。")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(StoreTheme.ink.opacity(0.64))
                }
            }

            Text(action.message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(StoreTheme.ink.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(parentGateChallenge.question)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(StoreTheme.ink)

                TextField("答案", text: $parentGateAnswer)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(.title3.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(StoreTheme.berry.opacity(0.24), lineWidth: 1.5)
                    )

                if let parentGateMessage {
                    Text(parentGateMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(StoreTheme.berry)
                }
            }

            HStack(spacing: 10) {
                Button("取消") {
                    parentGateAction = nil
                }
                .buttonStyle(StoreSecondaryButtonStyle())

                Button(action.confirmTitle) {
                    submitParentGate(for: action)
                }
                .buttonStyle(StorePrimaryButtonStyle())
                .disabled(parentGateAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
    }
}

private enum ParentGateAction: String, Identifiable {
    case purchase
    case restore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .purchase:
            "家長確認購買"
        case .restore:
            "家長確認恢復購買"
        }
    }

    var message: String {
        switch self {
        case .purchase:
            "答對後才會開啟 Apple 付款畫面。這項購買會移除廣告。"
        case .restore:
            "答對後才會向 Apple 查詢既有購買紀錄，不會產生新的付款。"
        }
    }

    var confirmTitle: String {
        switch self {
        case .purchase:
            "繼續購買"
        case .restore:
            "繼續恢復"
        }
    }
}

struct ParentGateChallenge {
    let question: String
    let answer: String

    static func make() -> ParentGateChallenge {
        let left = Int.random(in: 1...9)
        let right = Int.random(in: 1...9)
        let product = left * right
        let shouldAdd = Bool.random()
        let adjustment = shouldAdd
            ? Int.random(in: 1...9)
            : Int.random(in: 1...min(9, product))
        let result = shouldAdd ? product + adjustment : product - adjustment
        let operatorText = shouldAdd ? "+" : "-"

        return ParentGateChallenge(
            question: "請計算 \(left) × \(right) \(operatorText) \(adjustment) 的答案",
            answer: "\(result)"
        )
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
