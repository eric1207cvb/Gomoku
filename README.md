# Gomoku

SwiftUI 五子棋 iOS/iPadOS app。介面以 iPad 為主，iPhone 會切成直向捲動版；AI 是本機規則搜尋引擎，不需要連線或雲端模型。

## 目前包含

- 15x15 五子棋棋盤，五連或以上獲勝。
- 單人 AI 對戰與本機雙人模式。
- 入門、普通、困難、家長挑戰四種難易度。
- 本機 AI：候選點排序、棋型評估、alpha-beta minimax。
- Kids Category 送審版本不包含第三方廣告、第三方分析、訂閱或 App 內購買。
- App Icon、PrivacyInfo、Info.plist、Xcode project、核心邏輯測試。
- GitHub Pages 隱私權頁面：`docs/privacy.html`。

## 開啟專案

用 Xcode 開啟：

```bash
open Gomoku.xcodeproj
```

用完整 Xcode 開啟後，先在 target 的 Signing & Capabilities 設定你的 Team。

也可以用命令列建置到模擬器：

```bash
xcodebuild -project Gomoku.xcodeproj -scheme Gomoku -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

## Kids Category 送審策略

目前送審版本已移除第三方廣告與移除廣告內購：

- 不引用 Google Mobile Ads SDK。
- 不引用 RevenueCat SDK。
- 不設定 `GADApplicationIdentifier` 或 `SKAdNetworkItems`。
- 不使用 IDFA，不要求 App Tracking Transparency。
- 不包含訂閱、一次性內購或付費解鎖。
- 核心玩法與 AI 都在裝置本機執行。

## 法律與隱私

- App 內法律頁包含 Apple 標準 EULA、COPPA 與隱私摘要。
- 正式隱私頁：`https://eric1207cvb.github.io/Gomoku/privacy.html`
- GitHub Pages 來源檔：`docs/privacy.html`
- 聯絡信箱設定在 [GomokuApp/AppConfig.swift](GomokuApp/AppConfig.swift)。

## 測試核心邏輯

```bash
swift test
```

這只測 `GomokuCore`，不需要第三方 SDK。

## 主要檔案

- [Sources/GomokuCore/GomokuBoard.swift](Sources/GomokuCore/GomokuBoard.swift)：棋盤、落子、勝負判斷。
- [Sources/GomokuCore/LocalGomokuAI.swift](Sources/GomokuCore/LocalGomokuAI.swift)：本機 AI。
- [GomokuApp/GameViewModel.swift](GomokuApp/GameViewModel.swift)：遊戲流程。
- [GomokuApp/Views/GomokuBoardView.swift](GomokuApp/Views/GomokuBoardView.swift)：棋盤繪製與點擊座標。
