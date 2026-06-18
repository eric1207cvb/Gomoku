import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var monetization: MonetizationStore
    @State private var showingStore = false
    @State private var showingLegal = false
    @State private var showingStoreParentGate = false
    @State private var storeParentGateChallenge = ParentGateChallenge.make()
    @State private var storeParentGateAnswer = ""
    @State private var storeParentGateMessage: String?
    @State private var showingVictoryCelebration = false
    @State private var showingEncouragementCelebration = false
    @State private var victoryCelebrationID = 0
    @State private var encouragementCelebrationID = 0

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let isPhoneLandscape = isLandscape && proxy.size.height < 500
            let landscapeChromeReserve: CGFloat = isLandscape ? (isPhoneLandscape ? 56 : 78) : 0
            let usesSidebar = proxy.size.width >= 900 && proxy.size.height >= 640 && isLandscape
            let usesCompactLandscape = !usesSidebar && isLandscape && proxy.size.width >= 560
            let isTabletPortrait = proxy.size.width >= 700 && !usesSidebar

            NavigationStack {
                ZStack(alignment: .top) {
                    PlayfulBackdrop()

                    if usesSidebar {
                        let outerPadding: CGFloat = 10
                        let gap: CGFloat = 12
                        let panelWidth = min(300, max(278, proxy.size.width * 0.22))
                        let statusHeight: CGFloat = 64
                        let boardSpacing: CGFloat = 6
                        let usableWidth = proxy.size.width - outerPadding * 2 - gap - panelWidth
                        let usableHeight = proxy.size.height - landscapeChromeReserve - outerPadding * 2 - statusHeight - boardSpacing - 12
                        let boardDimension = max(320, min(usableWidth, usableHeight))

                        HStack(alignment: .top, spacing: gap) {
                            boardArea(boardDimension: boardDimension, compact: true)
                                .frame(width: boardDimension)
                            ScrollView {
                                controlPanel(compact: false)
                            }
                            .scrollIndicators(.hidden)
                            .frame(width: panelWidth)
                            .frame(maxHeight: proxy.size.height - outerPadding * 2)
                        }
                        .padding(.horizontal, outerPadding)
                        .padding(.top, outerPadding)
                    } else if usesCompactLandscape {
                        let outerPadding: CGFloat = 8
                        let gap: CGFloat = 10
                        let panelWidth = min(320, max(270, proxy.size.width * 0.34))
                        let boardAvailableWidth = proxy.size.width - outerPadding * 2 - gap - panelWidth
                        let boardAvailableHeight = proxy.size.height - landscapeChromeReserve - outerPadding * 2 - 12
                        let boardDimension = max(220, min(boardAvailableWidth, boardAvailableHeight))

                        HStack(alignment: .top, spacing: gap) {
                            boardArea(
                                boardDimension: boardDimension,
                                compact: true,
                                showsStatusBar: false,
                                showsBoardStickers: false
                            )
                                .frame(width: boardDimension)

                            ScrollView {
                                controlPanel(compact: true)
                            }
                            .scrollIndicators(.hidden)
                            .frame(width: panelWidth)
                            .frame(maxHeight: proxy.size.height - outerPadding * 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, outerPadding)
                        .padding(.top, outerPadding)
                    } else if isTabletPortrait {
                        let outerPadding: CGFloat = 10
                        let statusHeight: CGFloat = 64
                        let boardSpacing: CGFloat = 6
                        let toolbarSpacing: CGFloat = 8
                        let toolbarHeight: CGFloat = 128
                        let usableWidth = proxy.size.width - outerPadding * 2
                        let usableHeight = proxy.size.height - outerPadding - statusHeight - boardSpacing - toolbarSpacing - toolbarHeight - 6
                        let boardDimension = max(380, min(usableWidth, usableHeight))

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
                        let outerPadding: CGFloat = 10
                        let statusHeight: CGFloat = 64
                        let dashboardHeight: CGFloat = 150
                        let spacing: CGFloat = 8
                        let usableWidth = proxy.size.width - outerPadding * 2
                        let usableHeight = proxy.size.height - outerPadding * 2 - statusHeight - dashboardHeight - spacing * 2
                        let boardDimension = min(usableWidth, max(270, usableHeight))

                        ViewThatFits(in: .vertical) {
                            VStack(spacing: spacing) {
                                boardArea(boardDimension: boardDimension, compact: true)
                                    .frame(width: boardDimension)
                                centeredFunctionBar
                                    .frame(width: boardDimension)
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(.horizontal, outerPadding)
                            .padding(.top, outerPadding)

                            ScrollView {
                                VStack(spacing: spacing) {
                                    boardArea(boardDimension: boardDimension, compact: true)
                                        .frame(width: boardDimension)
                                    centeredFunctionBar
                                        .frame(width: boardDimension)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, outerPadding)
                                .padding(.top, outerPadding)
                            }
                        }
                    }

                    if showingVictoryCelebration, let winner = viewModel.outcome.winner {
                        VictoryCelebrationOverlay(winner: winner)
                            .id(victoryCelebrationID)
                            .allowsHitTesting(false)
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            .zIndex(20)
                    }

                    if showingEncouragementCelebration {
                        EncouragementCelebrationOverlay(difficulty: viewModel.difficulty)
                            .id(encouragementCelebrationID)
                            .allowsHitTesting(false)
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            .zIndex(21)
                    }

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationTitle(isPhoneLandscape ? "" : "五子棋")
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

                    #if DEBUG && canImport(GoogleMobileAds) && os(iOS)
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            monetization.presentAdInspector()
                        } label: {
                            Image(systemName: "stethoscope")
                        }
                        .accessibilityLabel("Ad Inspector")
                    }
                    #endif

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            requestStoreParentGate()
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

                    #if DEBUG && canImport(GoogleMobileAds) && os(iOS)
                    ToolbarItem {
                        Button {
                            monetization.presentAdInspector()
                        } label: {
                            Image(systemName: "stethoscope")
                        }
                        .accessibilityLabel("Ad Inspector")
                    }
                    #endif

                    ToolbarItem {
                        Button {
                            requestStoreParentGate()
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
                .sheet(isPresented: $showingStoreParentGate) {
                    storeParentGateSheet
                        .presentationDetents([.height(360), .medium])
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
                .onChange(of: viewModel.board.movesPlayed) { oldCount, newCount in
                    if newCount > oldCount {
                        StoneDropHaptics.playIfPhone()
                    }
                }
            }
        }
    }

    private var showsBeginnerHintControls: Bool {
        viewModel.difficulty == .beginner
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
    private func restartGame() {
        withAnimation(.easeInOut(duration: 0.16)) {
            showingVictoryCelebration = false
            showingEncouragementCelebration = false
        }
        viewModel.startNewGame()
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

    private func requestStoreParentGate() {
        guard !monetization.adsRemoved else {
            showingStore = true
            return
        }

        storeParentGateChallenge = ParentGateChallenge.make()
        storeParentGateAnswer = ""
        storeParentGateMessage = nil
        showingStoreParentGate = true
    }

    private func submitStoreParentGate() {
        let normalizedAnswer = storeParentGateAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedAnswer == storeParentGateChallenge.answer else {
            storeParentGateMessage = "爸爸媽媽加油！！請再試一次吧！！"
            storeParentGateChallenge = ParentGateChallenge.make()
            storeParentGateAnswer = ""
            return
        }

        showingStoreParentGate = false
        storeParentGateAnswer = ""
        storeParentGateMessage = nil

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            showingStore = true
        }
    }

    private var storeParentGateSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(KidTheme.berry)

                VStack(alignment: .leading, spacing: 4) {
                    Text("親子鎖")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(KidTheme.ink)
                    Text("移除廣告由家長設定")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KidTheme.ink.opacity(0.64))
                }
            }

            Text("通過確認後才會開啟移除廣告頁面；真正購買前仍會再確認一次。")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KidTheme.ink.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(storeParentGateChallenge.question)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(KidTheme.ink)

                TextField("答案", text: $storeParentGateAnswer)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(.title3.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(KidTheme.berry.opacity(0.24), lineWidth: 1.5)
                    )

                if let storeParentGateMessage {
                    Text(storeParentGateMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KidTheme.berry)
                }
            }

            HStack(spacing: 10) {
                Button("取消") {
                    showingStoreParentGate = false
                }
                .buttonStyle(CuteSecondaryButtonStyle())

                Button("開啟") {
                    submitStoreParentGate()
                }
                .buttonStyle(CutePrimaryButtonStyle())
                .disabled(storeParentGateAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
    }

    private func boardArea(
        boardDimension: CGFloat?,
        compact: Bool,
        showsStatusBar: Bool = true,
        showsBoardStickers: Bool = true
    ) -> some View {
        VStack(spacing: compact ? 8 : 16) {
            if showsStatusBar {
                CuteStatusBar(
                    title: viewModel.statusTitle,
                    subtitle: "手數 \(viewModel.moveCountText)",
                    isThinking: viewModel.isAIThinking,
                    compact: compact,
                    onNewGame: restartGame
                )
                .frame(height: compact ? 64 : nil)
            }

            GomokuBoardView(
                board: viewModel.board,
                lastMove: viewModel.lastMove,
                winningLine: viewModel.winningLine,
                hintMoves: viewModel.boardGuideMoves,
                aiHighlightedMove: viewModel.aiHighlightedMove,
                canTap: viewModel.canTapBoard,
                onTap: { move in
                    submitMove(move)
                }
            )
            .id(viewModel.gameID)
            .frame(width: boardDimension, height: boardDimension)
            .frame(maxWidth: boardDimension == nil ? 720 : nil)
            .overlay(alignment: .topTrailing) {
                if showsBoardStickers {
                    CandySticker(systemImage: "star.fill", color: KidTheme.sunny, compact: compact)
                        .offset(x: compact ? 6 : 8, y: compact ? -6 : -8)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if showsBoardStickers {
                    CandySticker(systemImage: "heart.fill", color: KidTheme.berry, compact: compact)
                        .offset(x: compact ? -5 : -7, y: compact ? 5 : 7)
                }
            }
        }
    }

    private func controlPanel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 9 : 11) {
            if compact {
                HStack(spacing: 8) {
                    dashboardHeader(compact: compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        restartGame()
                    } label: {
                        Label("新局", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(CutePrimaryButtonStyle(compact: true))
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("新局")
                }
            } else {
                dashboardHeader(compact: compact)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                turnInfoChip(compact: compact)
                secondaryInfoChip(compact: compact)
            }

            ControlSection(title: "模式", systemImage: "gamecontroller.fill", compact: compact) {
                modeSelector(compact: compact)
            }

            if viewModel.mode == .versusAI {
                ControlSection(title: "先手", systemImage: "flag.checkered", compact: compact) {
                    firstMoveSelector(compact: compact)
                }
            }

            ControlSection(title: "難度", systemImage: "wand.and.stars", compact: compact) {
                difficultySelector(compact: compact)
            }

            beginnerHintStrip(compact: compact)

            dashboardActions(compact: compact)
        }
        .padding(compact ? 12 : 14)
        .background(CandyPanelBackground())
        .overlay(alignment: .topTrailing) {
            CandySticker(systemImage: "sparkles", color: KidTheme.lavender, compact: true)
                .offset(x: 8, y: -8)
        }
    }

    private var centeredFunctionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                dashboardHeader(compact: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                dashboardActions(compact: true)
                    .fixedSize(horizontal: true, vertical: false)
            }

            HStack(spacing: 8) {
                modeSelector(compact: true)
                    .frame(maxWidth: .infinity)
                difficultySelector(compact: true)
                    .frame(maxWidth: .infinity)
                if viewModel.mode == .versusAI {
                    firstMoveSelector(compact: true)
                        .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 8) {
                turnInfoChip(compact: true)
                secondaryInfoChip(compact: true)
            }

            beginnerHintStrip(compact: true)
        }
        .padding(10)
        .background(CandyPanelBackground())
        .overlay(alignment: .topTrailing) {
            CandySticker(systemImage: "sparkles", color: KidTheme.lavender, compact: true)
                .offset(x: 8, y: -8)
        }
    }

    @MainActor
    private func submitMove(_ move: Move) {
        viewModel.handleTap(on: move)
    }

    private var aiMoveText: String {
        if viewModel.mode == .localTwoPlayer {
            return "雙人"
        }
        if viewModel.isAIThinking {
            return "最多 3 秒"
        }
        if let lastAIMove = viewModel.lastAIMove {
            return lastAIMove.boardNotation
        }
        return "尚未"
    }

    @ViewBuilder
    private func secondaryInfoChip(compact: Bool) -> some View {
        if viewModel.mode == .localTwoPlayer {
            Button {
                viewModel.toggleTurnHandoffPrompt()
            } label: {
                FunctionInfoChip(
                    title: "回合提示",
                    value: viewModel.isTurnHandoffPromptEnabled ? "開啟" : "關閉",
                    systemImage: viewModel.isTurnHandoffPromptEnabled ? "bell.fill" : "bell.slash.fill",
                    color: viewModel.isTurnHandoffPromptEnabled ? KidTheme.mint : KidTheme.ink.opacity(0.54),
                    compact: compact
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("回合提示")
            .accessibilityValue(viewModel.isTurnHandoffPromptEnabled ? "開啟" : "關閉")
            .accessibilityHint("點兩下切換雙人模式回合提示")
        } else {
            FunctionInfoChip(
                title: "AI 落點",
                value: aiMoveText,
                systemImage: viewModel.isAIThinking ? "timer" : "mappin.circle.fill",
                color: KidTheme.berry,
                compact: compact
            )
        }
    }

    private func turnInfoChip(compact: Bool) -> some View {
        TurnInfoChip(
            stone: viewModel.currentTurn,
            isProminent: viewModel.mode == .localTwoPlayer && viewModel.isTurnHandoffPromptEnabled,
            compact: compact
        )
    }

    @ViewBuilder
    private func beginnerHintStrip(compact: Bool) -> some View {
        if showsBeginnerHintControls {
            VStack(alignment: .leading, spacing: compact ? 6 : 8) {
                if let title = viewModel.beginnerCoachTitle, let message = viewModel.beginnerCoachMessage {
                    BeginnerCoachBubble(title: title, message: message, compact: compact)
                }

                HStack(spacing: 8) {
                    Label("下一步提示", systemImage: viewModel.isBeginnerMoveHintEnabled ? "lightbulb.fill" : "lightbulb.slash.fill")
                        .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                        .foregroundStyle(KidTheme.ink)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Button {
                        viewModel.toggleBeginnerMoveHints()
                    } label: {
                        Label(
                            viewModel.isBeginnerMoveHintEnabled ? "關閉提示" : "開啟提示",
                            systemImage: viewModel.isBeginnerMoveHintEnabled ? "eye.slash.fill" : "eye.fill"
                        )
                    }
                    .buttonStyle(CuteSecondaryButtonStyle(compact: true))
                    .accessibilityLabel(viewModel.isBeginnerMoveHintEnabled ? "關閉下一步提示" : "開啟下一步提示")
                }

                if viewModel.isBeginnerMoveHintEnabled {
                    BeginnerHintEnabledChip(compact: compact)
                        .accessibilityLabel("下一步提示已開啟，請看棋盤上半透明的位置")
                } else {
                    Button {
                        viewModel.toggleBeginnerMoveHints()
                    } label: {
                        BeginnerHintDisabledChip(compact: compact)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("下一步提示已關閉，點兩下重新開啟")
                }
            }
        }
    }

    private func dashboardHeader(compact: Bool) -> some View {
        HStack(spacing: compact ? 8 : 10) {
            Image("GomokuMascots")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 36 : 48, height: compact ? 36 : 48)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: compact ? 1 : 2) {
                Text("五子棋")
                    .font((compact ? Font.subheadline : Font.headline).weight(.heavy))
                    .foregroundStyle(KidTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(viewModel.statusTitle)
                    .font((compact ? Font.caption2 : Font.caption).weight(.bold))
                    .foregroundStyle(viewModel.isAIThinking ? KidTheme.berry : KidTheme.ink.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
    }

    private func modeSelector(compact: Bool) -> some View {
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

    private func difficultySelector(compact: Bool) -> some View {
        Menu {
            ForEach(AIDifficulty.allCases) { difficulty in
                Button {
                    viewModel.selectDifficulty(difficulty)
                } label: {
                    if difficulty == viewModel.difficulty {
                        Label(difficulty.displayName, systemImage: "checkmark")
                    } else {
                        Text(difficulty.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: compact ? 5 : 7) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: compact ? 12 : 13, weight: .heavy))
                Text(viewModel.difficulty.displayName)
                    .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: compact ? 9 : 10, weight: .heavy))
            }
            .foregroundStyle(KidTheme.ink)
            .padding(.horizontal, compact ? 9 : 11)
            .padding(.vertical, compact ? 7 : 8)
            .background(.white.opacity(0.90), in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(KidTheme.berry.opacity(0.20), lineWidth: 1.25)
            )
        }
        .buttonStyle(.plain)
    }

    private func firstMoveSelector(compact: Bool) -> some View {
        Button {
            viewModel.toggleStartingPlayer()
        } label: {
            HStack(spacing: compact ? 5 : 7) {
                Image(systemName: viewModel.startingPlayer == .ai ? "cpu.fill" : "person.fill")
                    .font(.system(size: compact ? 12 : 13, weight: .heavy))
                Text(viewModel.startingPlayer.displayName)
                    .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: compact ? 9 : 10, weight: .heavy))
            }
            .foregroundStyle(KidTheme.ink)
            .padding(.horizontal, compact ? 9 : 11)
            .padding(.vertical, compact ? 7 : 8)
            .background(.white.opacity(0.90), in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke((viewModel.startingPlayer == .ai ? KidTheme.mint : KidTheme.berry).opacity(0.22), lineWidth: 1.25)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("先手")
        .accessibilityValue(viewModel.startingPlayer.displayName)
        .accessibilityHint("點兩下切換玩家先手或AI先手，並開始新局")
    }

    private func dashboardActions(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            Button {
                viewModel.undoMove()
            } label: {
                Label(compact ? "悔棋" : "悔棋一次", systemImage: "arrow.uturn.backward.circle.fill")
            }
            .buttonStyle(CuteSecondaryButtonStyle(compact: true))
            .disabled(!viewModel.canUndoMove)
            .accessibilityLabel("悔棋一次")
            .accessibilityValue(viewModel.undoStatusText)

            Button {
                requestStoreParentGate()
            } label: {
                Label(
                    monetization.adsRemoved ? (compact ? "已移除" : "已移除廣告") : (compact ? "廣告" : "移除廣告"),
                    systemImage: monetization.adsRemoved ? "checkmark.seal.fill" : "rectangle.slash"
                )
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

private struct FunctionInfoChip: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            Image(systemName: systemImage)
                .font(.system(size: compact ? 13 : 15, weight: .heavy))
                .foregroundStyle(color)
                .frame(width: compact ? 18 : 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font((compact ? Font.caption2 : Font.caption).weight(.bold))
                    .foregroundStyle(KidTheme.ink.opacity(0.54))
                    .lineLimit(1)
                Text(value)
                    .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                    .foregroundStyle(KidTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 6 : 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1.25)
        )
    }
}

private struct TurnInfoChip: View {
    let stone: Stone
    let isProminent: Bool
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            StoneToken(stone: stone)
                .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)
                .overlay {
                    if isProminent {
                        Circle()
                            .stroke(KidTheme.sunny.opacity(0.52), lineWidth: 2)
                            .padding(-4)
                    }
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(isProminent ? "輪到這一色" : "回合")
                    .font((compact ? Font.caption2 : Font.caption).weight(.bold))
                    .foregroundStyle(KidTheme.ink.opacity(0.54))
                    .lineLimit(1)
                Text(isProminent ? "\(stone.displayName)下" : stone.displayName)
                    .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                    .foregroundStyle(KidTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 6 : 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(isProminent ? 0.86 : 0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke((stone == .black ? KidTheme.ink : KidTheme.sunny).opacity(isProminent ? 0.28 : 0.18), lineWidth: 1.25)
        )
        .accessibilityLabel(isProminent ? "輪到\(stone.displayName)下" : "\(stone.displayName)回合")
    }
}

private struct BeginnerCoachBubble: View {
    let title: String
    let message: String
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 7 : 9) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: compact ? 14 : 16, weight: .heavy))
                .foregroundStyle(KidTheme.sunny)
                .frame(width: compact ? 20 : 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                    .foregroundStyle(KidTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(message)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(KidTheme.ink.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 6 : 8)
        .frame(maxWidth: .infinity, minHeight: compact ? 38 : 44, alignment: .leading)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(KidTheme.sunny.opacity(0.26), lineWidth: 1.25)
        )
    }
}

private struct BeginnerHintEnabledChip: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 7 : 9) {
            Image(systemName: "circle.dotted.circle.fill")
                .font(.system(size: compact ? 15 : 17, weight: .heavy))
                .foregroundStyle(KidTheme.mint)
                .frame(width: compact ? 22 : 26)

            VStack(alignment: .leading, spacing: 1) {
                Text("看棋盤上亮亮的位置")
                    .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                    .foregroundStyle(KidTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("輪到你時會出現")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(KidTheme.ink.opacity(0.56))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 7 : 8)
        .frame(maxWidth: .infinity, minHeight: compact ? 38 : 44, alignment: .leading)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(KidTheme.mint.opacity(0.22), lineWidth: 1.25)
        )
    }
}

private struct BeginnerHintDisabledChip: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 7 : 9) {
            Image(systemName: "lightbulb.slash.fill")
                .font(.system(size: compact ? 14 : 16, weight: .heavy))
                .foregroundStyle(KidTheme.ink.opacity(0.50))
                .frame(width: compact ? 22 : 26)

            VStack(alignment: .leading, spacing: 1) {
                Text("提示已關閉")
                    .font((compact ? Font.caption : Font.subheadline).weight(.heavy))
                    .foregroundStyle(KidTheme.ink)
                    .lineLimit(1)
                Text("點一下可以再開啟")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(KidTheme.ink.opacity(0.56))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 7 : 8)
        .frame(maxWidth: .infinity, minHeight: compact ? 38 : 44, alignment: .leading)
        .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(KidTheme.ink.opacity(0.12), lineWidth: 1.25)
        )
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
                .frame(width: compact ? 54 : 92, height: compact ? 42 : 72)
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

            Button {
                onNewGame()
            } label: {
                Label("新局", systemImage: "arrow.clockwise")
            }
            .buttonStyle(CutePrimaryButtonStyle(compact: compact))
            .contentShape(Capsule(style: .continuous))
            .allowsHitTesting(true)
            .zIndex(4)
            .accessibilityLabel("開始新局")
        }
        .padding(.horizontal, compact ? 10 : 16)
        .padding(.vertical, compact ? 5 : 10)
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
            .allowsHitTesting(false)
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
            .allowsHitTesting(false)
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
            .contentShape(Capsule(style: .continuous))
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
            .contentShape(Capsule(style: .continuous))
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
