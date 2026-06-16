# Gomoku

SwiftUI 五子棋 iOS/iPadOS app。介面以 iPad 為主，iPhone 會切成直向捲動版；AI 是本機規則搜尋引擎，不需要連線或雲端模型。

## 目前包含

- 15x15 五子棋棋盤，五連或以上獲勝。
- AI 對戰與本機雙人模式。
- 入門、普通、困難、高手四種難易度。
- 本機 AI：候選點排序、棋型評估、alpha-beta minimax。
- AdMob banner 服務層，未接 SDK 時會顯示 placeholder。
- RevenueCat 移除廣告服務層，使用 `remove_ads` entitlement。
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

## AdMob 設定

專案已引用官方 SPM repo：

```text
https://github.com/googleads/swift-package-manager-google-mobile-ads.git
```

目前設定為正式 AdMob 值：

- App ID: `ca-app-pub-8563333250584395~5604315500`
- Banner ad unit: `ca-app-pub-8563333250584395/6733605907`

若日後要更換 AdMob App 或廣告單元，請修改：

- [GomokuApp/AppConfig.swift](GomokuApp/AppConfig.swift) 的 `admobAppID`、`admobBannerAdUnitID`
- [GomokuApp/Resources/Info.plist](GomokuApp/Resources/Info.plist) 的 `GADApplicationIdentifier`
- `SKAdNetworkItems` 建議依 Google AdMob 後台與官方文件補完整清單

參考：Google AdMob iOS quick start 與 banner guide  
https://developers.google.com/admob/ios/quick-start  
https://developers.google.com/admob/ios/banner

## RevenueCat 設定

專案已引用官方 SPM repo：

```text
https://github.com/RevenueCat/purchases-ios-spm.git
```

RevenueCat dashboard 建議：

- 建立一個 non-consumable 或 subscription product，例如 `gomoku.remove_ads`
- 建立 entitlement：`remove_ads`
- 將 product attach 到 `remove_ads`
- 建立 default offering，讓 app 可以抓到第一個 package

正式使用前請修改 [GomokuApp/AppConfig.swift](GomokuApp/AppConfig.swift)：

```swift
static let revenueCatAPIKey = "你的 RevenueCat public Apple API key"
static let removeAdsEntitlementID = "remove_ads"
```

參考：RevenueCat iOS installation、SDK configure、customer info、purchase docs  
https://www.revenuecat.com/docs/getting-started/installation/ios  
https://www.revenuecat.com/docs/getting-started/configuring-sdk  
https://www.revenuecat.com/docs/customers/customer-info  
https://www.revenuecat.com/docs/getting-started/making-purchases

## 法律與隱私

- App 內法律頁包含 Apple 標準 EULA、COPPA 與隱私摘要。
- 正式隱私頁：`https://eric1207cvb.github.io/Gomoku/privacy.html`
- GitHub Pages 來源檔：`docs/privacy.html`
- 聯絡信箱設定在 [GomokuApp/AppConfig.swift](GomokuApp/AppConfig.swift)。

## 測試核心邏輯

```bash
swift test
```

這只測 `GomokuCore`，不需要 AdMob/RevenueCat SDK。

## 主要檔案

- [Sources/GomokuCore/GomokuBoard.swift](Sources/GomokuCore/GomokuBoard.swift)：棋盤、落子、勝負判斷。
- [Sources/GomokuCore/LocalGomokuAI.swift](Sources/GomokuCore/LocalGomokuAI.swift)：本機 AI。
- [GomokuApp/GameViewModel.swift](GomokuApp/GameViewModel.swift)：遊戲流程。
- [GomokuApp/Views/GomokuBoardView.swift](GomokuApp/Views/GomokuBoardView.swift)：棋盤繪製與點擊座標。
- [GomokuApp/Services/MonetizationStore.swift](GomokuApp/Services/MonetizationStore.swift)：AdMob/RevenueCat 接線。
