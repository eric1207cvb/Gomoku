import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var parentAnswer = ""
    @State private var parentGateChallenge = ParentGateChallenge.make()
    @State private var linksUnlocked = false
    @State private var gateMessage: String?

    private let updatedDate = "2026-06-16"
    private let coppaGuideURL = URL(string: "https://www.ftc.gov/business-guidance/resources/childrens-online-privacy-protection-rule-six-step-compliance-plan-your-business")!
    private let appleGuidelinesURL = URL(string: "https://developer.apple.com/app-store/review/guidelines/")!

    var body: some View {
        NavigationStack {
            ZStack {
                LegalBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        summarySection
                        eulaSection
                        coppaSection
                        privacySection
                        adsSection
                        parentLinksSection
                        contactSection
                    }
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                }
            }
            .navigationTitle("法律與隱私")
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
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("GomokuMascots")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 76)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("家長安心資訊")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(LegalTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("五子棋給孩子玩，也讓家長知道資料與廣告怎麼處理。")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LegalTheme.ink.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(LegalCardBackground())
    }

    private var summarySection: some View {
        LegalSection(title: "重點摘要", systemImage: "star.circle.fill") {
            LegalPoint(systemImage: "person.crop.circle.badge.xmark", text: "不需要註冊帳號，也不會要求孩子輸入姓名、電話、地址、精確位置、照片或語音。")
            LegalPoint(systemImage: "cpu.fill", text: "五子棋 AI 在裝置上運算；棋盤、手數、模式與難易度只用來進行目前遊戲。")
            LegalPoint(systemImage: "bubble.left.and.bubble.right.fill", text: "沒有公開聊天、社群貼文或讓孩子互相傳訊的功能。")
            LegalPoint(systemImage: "rectangle.slash", text: "免費版有 Google AdMob 廣告版位；家長可透過 RevenueCat 與 Apple 內購移除廣告。")
        }
    }

    private var eulaSection: some View {
        LegalSection(title: "Apple 標準 EULA", systemImage: "doc.text.fill") {
            LegalPoint(systemImage: "checkmark.seal.fill", text: "除非日後另行提供自訂條款，本 App 在 App Store 下載與使用時，適用 Apple 標準終端使用者授權合約。")
            LegalPoint(systemImage: "cart.fill", text: "移除廣告的購買與恢復購買由 Apple App Store 付款流程處理，購買狀態由 RevenueCat 協助同步。")
            LegalPoint(systemImage: "lock.shield.fill", text: "移除廣告頁面、購買與恢復購買都會先要求家長完成親子鎖確認。")
        }
    }

    private var coppaSection: some View {
        LegalSection(title: "COPPA 與兒童隱私", systemImage: "figure.2.and.child.holdinghands") {
            LegalPoint(systemImage: "hand.raised.fill", text: "本 App 以兒童與家庭使用情境設計，不會主動向 13 歲以下兒童索取可識別個人的資料。")
            LegalPoint(systemImage: "envelope.fill", text: "如果家長認為孩子曾提供個人資料，或想查詢、刪除與孩子相關的資料，請使用下方聯絡信箱。")
            LegalPoint(systemImage: "megaphone.fill", text: "廣告請求會標示為兒童導向與未達同意年齡，並限制一般級廣告內容。")
        }
    }

    private var privacySection: some View {
        LegalSection(title: "隱私權聲明", systemImage: "lock.shield.fill") {
            LegalPoint(systemImage: "gamecontroller.fill", text: "遊戲資料：棋局狀態、最後落點、目前回合、模式與難易度只用於顯示與判斷遊戲。")
            LegalPoint(systemImage: "creditcard.fill", text: "購買資料：Apple 與 RevenueCat 會處理內購、恢復購買與移除廣告權益狀態；本 App 不會直接接收信用卡資料。")
            LegalPoint(systemImage: "antenna.radiowaves.left.and.right", text: "廣告資料：Google AdMob 可能依其 SDK 處理廣告請求所需資料；本 App 已設定兒童導向、未達同意年齡、非個人化與一般級內容限制。")
            LegalPoint(systemImage: "trash.fill", text: "資料刪除：若有任何與孩子相關的資料查詢或刪除需求，請由家長聯絡我們處理。")
        }
    }

    private var adsSection: some View {
        LegalSection(title: "廣告與移除廣告", systemImage: "sparkles.tv.fill") {
            LegalPoint(systemImage: "rectangle.inset.filled", text: "廣告只放在畫面下方版位，避免遮住棋盤操作。")
            LegalPoint(systemImage: "shield.lefthalf.filled", text: "面向兒童的版本不應使用行為式個人化廣告；目前程式已關閉個人化處理並限制廣告內容級別。")
            LegalPoint(systemImage: "checkmark.circle.fill", text: "家長購買移除廣告後，App 會隱藏廣告版位；重新安裝或換裝置時可使用恢復購買。")
        }
    }

    private var parentLinksSection: some View {
        LegalSection(title: "家長連結", systemImage: linksUnlocked ? "lock.open.fill" : "lock.fill") {
            Text("下面的按鈕會開啟外部網站，請由家長操作。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LegalTheme.ink.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)

            if linksUnlocked {
                VStack(spacing: 10) {
                    Link(destination: AppConfig.appleStandardEULAURL) {
                        LegalExternalLinkLabel(title: "Apple 標準 EULA", systemImage: "doc.text.fill")
                    }

                    if let privacyPolicyURL = AppConfig.privacyPolicyURL {
                        Link(destination: privacyPolicyURL) {
                            LegalExternalLinkLabel(title: "正式隱私權頁面", systemImage: "safari.fill")
                        }
                    } else {
                        LegalUnavailableLinkLabel(title: "正式隱私權頁面尚未設定", systemImage: "safari.fill")
                    }

                    Link(destination: coppaGuideURL) {
                        LegalExternalLinkLabel(title: "FTC COPPA 說明", systemImage: "building.columns.fill")
                    }
                    Link(destination: appleGuidelinesURL) {
                        LegalExternalLinkLabel(title: "Apple App Review Guidelines", systemImage: "apple.logo")
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(parentGateChallenge.question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LegalTheme.ink)

                    HStack(spacing: 10) {
                        TextField("答案", text: $parentAnswer)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .font(.headline.weight(.bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 84)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(LegalTheme.sky.opacity(0.32), lineWidth: 1.5)
                            )

                        Button("解鎖") {
                            unlockParentLinks()
                        }
                        .buttonStyle(LegalSmallButtonStyle())
                    }

                    if let gateMessage {
                        Text(gateMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(LegalTheme.berry)
                    }
                }
            }
        }
    }

    private var contactSection: some View {
        LegalSection(title: "家長聯絡", systemImage: "envelope.open.fill") {
            LegalPoint(systemImage: "mail.fill", text: "隱私、COPPA、資料刪除或廣告問題：\(AppConfig.privacyContactEmail)")
            LegalPoint(systemImage: "calendar", text: "最後更新：\(updatedDate)")
        }
    }

    private func unlockParentLinks() {
        if parentAnswer.trimmingCharacters(in: .whitespacesAndNewlines) == parentGateChallenge.answer {
            linksUnlocked = true
            parentAnswer = ""
            gateMessage = nil
        } else {
            gateMessage = "爸爸媽媽加油！！請再試一次吧！！"
            parentGateChallenge = ParentGateChallenge.make()
            parentAnswer = ""
        }
    }
}

private struct LegalSection<Content: View>: View {
    let title: String
    let systemImage: String
    private let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.heavy))
                .foregroundStyle(LegalTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
        }
        .padding(16)
        .background(LegalCardBackground())
    }
}

private struct LegalPoint: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(LegalTheme.mint.opacity(0.18))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LegalTheme.berry)
                )
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LegalTheme.ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LegalExternalLinkLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .heavy))
                .frame(width: 22)
            Text(title)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .heavy))
        }
        .foregroundStyle(LegalTheme.berry)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(LegalTheme.berry.opacity(0.18), lineWidth: 1.5)
        )
    }
}

private struct LegalUnavailableLinkLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .heavy))
                .frame(width: 22)
            Text(title)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer(minLength: 0)
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .heavy))
        }
        .foregroundStyle(LegalTheme.ink.opacity(0.48))
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(LegalTheme.ink.opacity(0.10), lineWidth: 1.5)
        )
    }
}

private struct LegalSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [LegalTheme.berry, LegalTheme.coral], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

private struct LegalCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.92),
                        LegalTheme.marshmallow.opacity(0.82),
                        LegalTheme.mint.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.88), lineWidth: 1.5)
            )
            .shadow(color: LegalTheme.lavender.opacity(0.20), radius: 14, x: 0, y: 8)
    }
}

private struct LegalBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.94, blue: 0.78),
                    Color(red: 0.86, green: 0.98, blue: 0.93),
                    Color(red: 1.00, green: 0.89, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                HStack {
                    Image(systemName: "star.fill")
                    Spacer()
                    Image(systemName: "heart.fill")
                }
                Spacer()
                HStack {
                    Image(systemName: "sparkles")
                    Spacer()
                    Image(systemName: "seal.fill")
                }
            }
            .font(.system(size: 22, weight: .heavy))
            .foregroundStyle(LegalTheme.berry.opacity(0.16))
            .padding(34)
        }
        .ignoresSafeArea()
    }
}

private enum LegalTheme {
    static let ink = Color(red: 0.18, green: 0.17, blue: 0.30)
    static let berry = Color(red: 0.91, green: 0.25, blue: 0.48)
    static let coral = Color(red: 1.00, green: 0.48, blue: 0.36)
    static let mint = Color(red: 0.27, green: 0.78, blue: 0.62)
    static let sky = Color(red: 0.30, green: 0.67, blue: 0.94)
    static let lavender = Color(red: 0.60, green: 0.50, blue: 0.94)
    static let marshmallow = Color(red: 1.00, green: 0.91, blue: 0.96)
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
