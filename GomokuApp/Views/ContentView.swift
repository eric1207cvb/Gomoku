import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var monetization: MonetizationStore
    @State private var showingStore = false
    @State private var showingLegal = false
    @State private var showingVictoryCelebration = false
    @State private var showingEncouragementCelebration = false
    @State private var victoryCelebrationID = 0
    @State private var encouragementCelebrationID = 0

    var body: some View {
        GeometryReader { proxy in
            let usesSidebar = proxy.size.width >= 900 && proxy.size.width > proxy.size.height
            let isTabletPortrait = proxy.size.width >= 700 && !usesSidebar

            NavigationStack {
                ZStack(alignment: .top) {
                    PlayfulBackdrop()

                    if usesSidebar {
                        let outerPadding: CGFloat = 14
                        let gap: CGFloat = 18
                        let panelWidth = min(330, max(300, proxy.size.width * 0.25))
                        let statusHeight: CGFloat = 74
                        let boardSpacing: CGFloat = 8
                        let usableWidth = proxy.size.width - outerPadding * 2 - gap - panelWidth
                        let usableHeight = proxy.size.height - outerPadding - statusHeight - boardSpacing - 8
                        let boardDimension = max(520, min(usableWidth, usableHeight))

                        HStack(alignment: .top, spacing: gap) {
                            boardArea(boardDimension: boardDimension, compact: true)
                                .frame(width: boardDimension)
                            controlPanel(compact: false)
                                .frame(width: panelWidth)
                        }
                        .padding(.horizontal, outerPadding)
                        .padding(.top, outerPadding)
                    } else if isTabletPortrait {
                        let outerPadding: CGFloat = 12
                        let statusHeight: CGFloat = 74
                        let boardSpacing: CGFloat = 8
                        let toolbarSpacing: CGFloat = 12
                        let toolbarHeight: CGFloat = 158
                        let usableWidth = proxy.size.width - outerPadding * 2
                        let usableHeight = proxy.size.height - outerPadding - statusHeight - boardSpacing - toolbarSpacing - toolbarHeight - 8
                        let boardDimension = max(420, min(usableWidth, usableHeight))

                        VStack(spacing: toolbarSpacing) {
                            boardArea(boardDimension: boardDimension, compact: true)
                                .frame(width: boardDimension)
                            centeredFunctionBar
                                .frame(width: boardDimension)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, outerPadding)
                        .padding(.top, outerPadding)
                    } else {
                        ScrollView {
                            VStack(spacing: 18) {
                                boardArea(boardDimension: nil, compact: false)
                                controlPanel(compact: false)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                        }
                    }

                    if showingVictoryCelebration, let winner = viewModel.outcome.winner {
                        VictoryCelebrationOverlay(winner: winner)
                            .id(victoryCelebrationID)
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            .zIndex(20)
                    }

                    if showingEncouragementCelebration {
                        EncouragementCelebrationOverlay()
                            .id(encouragementCelebrationID)
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            .zIndex(21)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationTitle("五子棋")
                .inlineNavigationTitle()
                .tint(KidTheme.berry)
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingLegal = true
                        } label: {
                            Image(systemName: "doc.text.fill")
                        }
                        .accessibilityLabel("法律與隱私")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingStore = true
                        } label: {
                            Image(systemName: monetization.adsRemoved ? "checkmark.seal.fill" : "rectangle.slash")
                        }
                        .accessibilityLabel("移除廣告")
                    }
                    #else
                    ToolbarItem {
                        Button {
                            showingLegal = true
                        } label: {
                            Image(systemName: "doc.text.fill")
                        }
                        .accessibilityLabel("法律與隱私")
                    }

                    ToolbarItem {
                        Button {
                            showingStore = true
                        } label: {
                            Image(systemName: monetization.adsRemoved ? "checkmark.seal.fill" : "rectangle.slash")
                        }
                        .accessibilityLabel("移除廣告")
                    }
                    #endif
                }
                .safeAreaInset(edge: .bottom) {
                    AdBannerSlot()
                        .environmentObject(monetization)
                }
                .sheet(isPresented: $showingStore) {
                    RemoveAdsView()
                        .environmentObject(monetization)
                        .presentationDetents([.medium])
                }
                .sheet(isPresented: $showingLegal) {
                    LegalView()
                        .presentationDetents([.large])
                }
                .onChange(of: viewModel.outcome) { _, newOutcome in
                    handleOutcomeChange(newOutcome)
                }
            }
        }
    }

    @MainActor
    private func handleOutcomeChange(_ outcome: GameOutcome) {
        switch outcome {
        case .win(_, _):
            if viewModel.isAIVictory(outcome) {
                playEncouragementCelebration()
            } else {
                playVictoryCelebration()
            }
        case .ongoing, .draw:
            withAnimation(.easeInOut(duration: 0.2)) {
                showingVictoryCelebration = false
                showingEncouragementCelebration = false
            }
        }
    }

    @MainActor
    private func playVictoryCelebration() {
        victoryCelebrationID += 1
        let activeID = victoryCelebrationID

        CelebrationHaptics.playWin()
        withAnimation(.easeOut(duration: 0.16)) {
            showingEncouragementCelebration = false
            showingVictoryCelebration = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            guard victoryCelebrationID == activeID else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                showingVictoryCelebration = false
            }
        }
    }

    @MainActor
    private func playEncouragementCelebration() {
        encouragementCelebrationID += 1
        let activeID = encouragementCelebrationID

        CelebrationHaptics.playEncouragement()
        withAnimation(.easeOut(duration: 0.18)) {
            showingVictoryCelebration = false
            showingEncouragementCelebration = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_200_000_000)
            guard encouragementCelebrationID == activeID else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                showingEncouragementCelebration = false
            }
        }
    }

    private func boardArea(boardDimension: CGFloat?, compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 16) {
            CuteStatusBar(
                title: viewModel.statusTitle,
                subtitle: "手數 \(viewModel.moveCountText)",
                isThinking: viewModel.isAIThinking,
                compact: compact,
                onNewGame: viewModel.startNewGame
            )
            .frame(height: compact ? 74 : nil)

            GomokuBoardView(
                board: viewModel.board,
                lastMove: viewModel.lastMove,
                winningLine: viewModel.winningLine,
                canTap: viewModel.canTapBoard,
                onTap: { move in
                    if viewModel.handleTap(on: move) {
                        StoneDropHaptics.playIfPhone()
                    }
                }
            )
            .frame(width: boardDimension, height: boardDimension)
            .frame(maxWidth: boardDimension == nil ? 720 : nil)
            .overlay(alignment: .topTrailing) {
                CandySticker(systemImage: "star.fill", color: KidTheme.sunny, compact: compact)
                    .offset(x: compact ? 6 : 8, y: compact ? -6 : -8)
            }
            .overlay(alignment: .bottomLeading) {
                CandySticker(systemImage: "heart.fill", color: KidTheme.berry, compact: compact)
                    .offset(x: compact ? -5 : -7, y: compact ? 5 : 7)
            }
        }
    }

    private func controlPanel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 17) {
            HStack(spacing: compact ? 8 : 12) {
                Image("GomokuMascots")
                    .resizable()
                    .scaledToFit()
                    .frame(width: compact ? 54 : 82, height: compact ? 54 : 82)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                    Text("五子棋")
                        .font((compact ? Font.headline : Font.title3).weight(.heavy))
                        .foregroundStyle(KidTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text("目前：\(viewModel.currentTurn.displayName)")
                        .font((compact ? Font.caption : Font.subheadline).weight(.semibold))
                        .foregroundStyle(KidTheme.berry)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                CuteIconBubble(systemImage: "star.fill", color: KidTheme.sunny)
                CuteIconBubble(systemImage: "heart.fill", color: KidTheme.berry)
                CuteIconBubble(systemImage: "sparkles", color: KidTheme.lavender)
            }

            ControlSection(title: "模式", systemImage: "gamecontroller.fill") {
                Picker("模式", selection: Binding(get: {
                    viewModel.mode
                }, set: {
                    viewModel.selectMode($0)
                })) {
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(compact ? .small : .regular)
            }

            ControlSection(title: "難易度", systemImage: "wand.and.stars") {
                Picker("難易度", selection: Binding(get: {
                    viewModel.difficulty
                }, set: {
                    viewModel.selectDifficulty($0)
                })) {
                    ForEach(AIDifficulty.allCases) { difficulty in
                        Text(difficulty.displayName).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(compact ? .small : .regular)
            }

            Divider()
                .overlay(KidTheme.sunny.opacity(0.85))

            HStack(spacing: 10) {
                StoneToken(stone: viewModel.currentTurn)
                    .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)
                Text(viewModel.currentTurn.displayName)
                    .font((compact ? Font.subheadline : Font.headline).weight(.bold))
                    .foregroundStyle(KidTheme.ink)
                Spacer(minLength: 0)
                if viewModel.isAIThinking {
                    ProgressView()
                        .controlSize(.small)
                        .tint(KidTheme.berry)
                }
            }

            MoveHistoryView(records: viewModel.moveHistory, limit: compact ? 4 : 8, compact: compact)

            Button {
                showingStore = true
            } label: {
                Label(monetization.adsRemoved ? "已移除廣告" : "移除廣告", systemImage: monetization.adsRemoved ? "checkmark.seal.fill" : "rectangle.slash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CuteSecondaryButtonStyle())
            .disabled(monetization.adsRemoved)

            Button {
                showingLegal = true
            } label: {
                Label("法律與隱私", systemImage: "lock.shield.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CuteSecondaryButtonStyle())
        }
        .padding(compact ? 14 : 18)
        .background(CandyPanelBackground())
        .overlay(alignment: .topTrailing) {
            CandySticker(systemImage: "sparkles", color: KidTheme.lavender, compact: true)
                .offset(x: 8, y: -8)
        }
    }

    private var centeredFunctionBar: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 12) {
                Image("GomokuMascots")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("五子棋")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(KidTheme.ink)
                        .lineLimit(1)
                    Text("目前：\(viewModel.currentTurn.displayName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KidTheme.berry)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    StoneToken(stone: viewModel.currentTurn)
                        .frame(width: 18, height: 18)
                    Text(viewModel.currentTurn.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KidTheme.ink)
                        .lineLimit(1)
                    if viewModel.isAIThinking {
                        ProgressView()
                            .controlSize(.small)
                            .tint(KidTheme.berry)
                    }
                }

                Button {
                    showingStore = true
                } label: {
                    Label(monetization.adsRemoved ? "已移除廣告" : "移除廣告", systemImage: monetization.adsRemoved ? "checkmark.seal.fill" : "rectangle.slash")
                }
                .buttonStyle(CuteSecondaryButtonStyle(compact: true))
                .disabled(monetization.adsRemoved)

                Button {
                    showingLegal = true
                } label: {
                    Label("隱私", systemImage: "lock.shield.fill")
                }
                .buttonStyle(CuteSecondaryButtonStyle(compact: true))
            }

            HStack(alignment: .top, spacing: 12) {
                ControlSection(title: "模式", systemImage: "gamecontroller.fill", compact: true) {
                    Picker("模式", selection: Binding(get: {
                        viewModel.mode
                    }, set: {
                        viewModel.selectMode($0)
                    })) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)

                ControlSection(title: "難易度", systemImage: "wand.and.stars", compact: true) {
                    Picker("難易度", selection: Binding(get: {
                        viewModel.difficulty
                    }, set: {
                        viewModel.selectDifficulty($0)
                    })) {
                        ForEach(AIDifficulty.allCases) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)

                MoveHistoryView(records: viewModel.moveHistory, limit: 3, compact: true)
                    .frame(width: 150)
            }
        }
        .padding(14)
        .background(CandyPanelBackground())
        .overlay(alignment: .topTrailing) {
            CandySticker(systemImage: "sparkles", color: KidTheme.lavender, compact: true)
                .offset(x: 8, y: -8)
        }
    }
}

private enum StoneDropHaptics {
    @MainActor
    static func playIfPhone() {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.prepare()
        impact.impactOccurred(intensity: 0.62)
        #endif
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

private struct MoveHistoryView: View {
    let records: [MoveRecord]
    var limit = 8
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 9) {
            Label("棋譜", systemImage: "list.bullet.clipboard.fill")
                .font((compact ? Font.subheadline : Font.headline).weight(.bold))
                .foregroundStyle(KidTheme.ink)

            if records.isEmpty {
                HStack(spacing: compact ? 6 : 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(KidTheme.sunny)
                    Text("尚未落子")
                        .font((compact ? Font.caption : Font.subheadline).weight(.semibold))
                        .foregroundStyle(KidTheme.ink.opacity(0.58))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, compact ? 3 : 6)
            } else {
                let recent = records.suffix(limit)
                VStack(spacing: compact ? 5 : 7) {
                    ForEach(recent) { record in
                        HStack {
                            Text("\(record.number)")
                                .font((compact ? Font.caption2 : Font.caption).weight(.bold).monospacedDigit())
                                .foregroundStyle(KidTheme.berry.opacity(0.74))
                                .frame(width: compact ? 20 : 28, alignment: .leading)
                            StoneToken(stone: record.stone)
                                .frame(width: compact ? 14 : 18, height: compact ? 14 : 18)
                            Text(record.notation)
                                .font((compact ? Font.caption : Font.subheadline).weight(.semibold).monospacedDigit())
                                .foregroundStyle(KidTheme.ink)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }
}

private struct CuteStatusBar: View {
    let title: String
    let subtitle: String
    let isThinking: Bool
    let compact: Bool
    let onNewGame: () -> Void

    var body: some View {
        HStack(spacing: compact ? 10 : 14) {
            Image("GomokuMascots")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 68 : 92, height: compact ? 54 : 72)
                .accessibilityHidden(true)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkles")
                        .font(.system(size: compact ? 10 : 12, weight: .heavy))
                        .foregroundStyle(KidTheme.sunny)
                        .offset(x: compact ? -2 : -4, y: compact ? 3 : 5)
                }

            VStack(alignment: .leading, spacing: compact ? 2 : 5) {
                HStack(spacing: 6) {
                    Text(title)
                        .font((compact ? Font.title3 : Font.title2).weight(.heavy))
                        .foregroundStyle(KidTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: compact ? 14 : 16, weight: .bold))
                        .foregroundStyle(KidTheme.sunny)
                }
                Text(subtitle)
                    .font((compact ? Font.footnote : Font.subheadline).weight(.semibold))
                    .foregroundStyle(KidTheme.ink.opacity(0.62))
            }

            Spacer(minLength: 10)

            if isThinking {
                ProgressView()
                    .tint(KidTheme.berry)
            }

            Button(action: onNewGame) {
                Label("新局", systemImage: "arrow.clockwise")
            }
            .buttonStyle(CutePrimaryButtonStyle(compact: compact))
        }
        .padding(.horizontal, compact ? 12 : 16)
        .padding(.vertical, compact ? 6 : 10)
        .background(CandyPanelBackground())
    }
}

private struct ControlSection<Content: View>: View {
    let title: String
    let systemImage: String
    var compact = false
    private let content: Content

    init(title: String, systemImage: String, compact: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.compact = compact
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 10) {
            Label(title, systemImage: systemImage)
                .font((compact ? Font.subheadline : Font.headline).weight(.bold))
                .foregroundStyle(KidTheme.ink)
            content
                .tint(KidTheme.berry)
        }
    }
}

private struct StoneToken: View {
    let stone: Stone

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: stone == .black
                        ? [Color(red: 0.26, green: 0.24, blue: 0.30), Color(red: 0.05, green: 0.05, blue: 0.08)]
                        : [Color.white, Color(red: 1.00, green: 0.93, blue: 0.80)],
                    center: .topLeading,
                    startRadius: 1,
                    endRadius: 14
                )
            )
            .overlay(
                Circle()
                    .stroke(stone == .black ? .white.opacity(0.14) : KidTheme.sunny.opacity(0.42), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.14), radius: 2, x: 0, y: 1)
    }
}

private struct CandyPanelBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.90),
                        KidTheme.marshmallow.opacity(0.78),
                        KidTheme.mint.opacity(0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: KidTheme.lavender.opacity(0.22), radius: 16, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.96), KidTheme.sunny.opacity(0.36), KidTheme.berry.opacity(0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
    }
}

private struct CandySticker: View {
    let systemImage: String
    let color: Color
    var compact = false

    var body: some View {
        Circle()
            .fill(.white.opacity(0.92))
            .frame(width: compact ? 30 : 38, height: compact ? 30 : 38)
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: compact ? 13 : 17, weight: .heavy))
                    .foregroundStyle(color)
            )
            .overlay(
                Circle()
                    .stroke(color.opacity(0.24), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.22), radius: 8, x: 0, y: 4)
            .accessibilityHidden(true)
    }
}

private struct CuteIconBubble: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Circle()
            .fill(color.opacity(0.16))
            .frame(width: 26, height: 26)
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(color)
            )
            .accessibilityHidden(true)
    }
}

private struct PlayfulBackdrop: View {
    private let icons = ["star.fill", "sparkle", "heart.fill", "seal.fill", "sparkles", "moon.stars.fill", "circle.hexagongrid.fill"]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.94, blue: 0.78),
                        Color(red: 0.86, green: 0.98, blue: 0.93),
                        Color(red: 0.89, green: 0.92, blue: 1.00),
                        Color(red: 1.00, green: 0.88, blue: 0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<18, id: \.self) { index in
                    Image(systemName: icons[index % icons.count])
                        .font(.system(size: 11 + CGFloat(index % 5) * 4, weight: .bold))
                        .foregroundStyle(confettiColor(index).opacity(index % 3 == 0 ? 0.32 : 0.20))
                        .rotationEffect(.degrees(Double(index * 29)))
                        .position(
                            x: proxy.size.width * xPosition(index),
                            y: proxy.size.height * yPosition(index)
                        )
                }
            }
            .ignoresSafeArea()
        }
    }

    private func confettiColor(_ index: Int) -> Color {
        [KidTheme.berry, KidTheme.sunny, KidTheme.mint, KidTheme.sky, KidTheme.lavender][index % 5]
    }

    private func xPosition(_ index: Int) -> CGFloat {
        [0.08, 0.18, 0.31, 0.47, 0.62, 0.76, 0.91, 0.12, 0.38, 0.69, 0.84, 0.24, 0.55, 0.96, 0.44, 0.73, 0.16, 0.88][index]
    }

    private func yPosition(_ index: Int) -> CGFloat {
        [0.12, 0.31, 0.18, 0.42, 0.16, 0.34, 0.11, 0.72, 0.82, 0.70, 0.88, 0.56, 0.93, 0.62, 0.27, 0.51, 0.47, 0.78][index]
    }
}

private struct CutePrimaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font((compact ? Font.subheadline : Font.headline).weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, compact ? 13 : 16)
            .padding(.vertical, compact ? 8 : 10)
            .background(
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [KidTheme.berry, KidTheme.coral], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: KidTheme.berry.opacity(configuration.isPressed ? 0.12 : 0.30), radius: configuration.isPressed ? 2 : 8, x: 0, y: configuration.isPressed ? 1 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

private struct CuteSecondaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font((compact ? Font.subheadline : Font.headline).weight(.bold))
            .foregroundStyle(KidTheme.berry)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, compact ? 12 : 14)
            .padding(.vertical, compact ? 8 : 11)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.72 : 0.92))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(KidTheme.berry.opacity(0.22), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

private enum KidTheme {
    static let ink = Color(red: 0.18, green: 0.17, blue: 0.30)
    static let berry = Color(red: 0.91, green: 0.25, blue: 0.48)
    static let coral = Color(red: 1.00, green: 0.48, blue: 0.36)
    static let sunny = Color(red: 1.00, green: 0.78, blue: 0.24)
    static let mint = Color(red: 0.27, green: 0.78, blue: 0.62)
    static let sky = Color(red: 0.30, green: 0.67, blue: 0.94)
    static let lavender = Color(red: 0.60, green: 0.50, blue: 0.94)
    static let marshmallow = Color(red: 1.00, green: 0.91, blue: 0.96)
}
