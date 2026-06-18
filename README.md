# Gomoku

SwiftUI 五子棋 iOS/iPadOS app。介面以 iPad 為主，iPhone 會切成直向捲動版；AI 是本機規則搜尋引擎，不需要連線或雲端模型。

## 目前包含

- 15x15 五子棋棋盤，五連或以上獲勝。
- 單人 AI 對戰與本機雙人模式。
- 入門、普通、困難、家長挑戰四種難易度。
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

正式 AdMob ID 不建議寫在公開 README；請在 app 設定檔中填入自己的值：

- App ID: `ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx`
- Banner ad unit: `ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx`

兒童/COPPA 廣告設定：

- 程式碼在 [GomokuApp/Services/MonetizationStore.swift](GomokuApp/Services/MonetizationStore.swift) 已設定：
  - `maxAdContentRating = .general`
  - `tagForChildDirectedTreatment = true`
  - `tagForUnderAgeOfConsent = true`
  - `publisherPrivacyPersonalizationState = .disabled`
- 目前不要求 App Tracking Transparency，也不要在兒童版加入 IDFA/追蹤授權提示。
- AdMob 後台建議：
  1. 左側進入「封鎖控制項」。
  2. 將最高廣告內容分級設為「一般觀眾」或等同 G 級。
  3. 封鎖不適合兒童的敏感類別，例如成人、約會、賭博、酒精、菸草、藥品、減重、政治、宗教或社交賭場類內容。
  4. 廣告格式維持 banner，避免插頁、獎勵廣告或會強迫孩子停下遊戲的格式。
  5. 使用 Ad Inspector 測試，確認廣告請求帶有兒童導向與非個人化處理。
- Debug 版本會在右上角顯示 Ad Inspector 工具按鈕；Release/App Store 版本不會編進去。
- Ad Inspector 需要測試裝置：在 AdMob 左側「設定」或首頁任務中加入 test device，或依 Xcode console 顯示的 test device identifier 加入。

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

建議使用一次性移除廣告：

1. 在 App Store Connect 建立 non-consumable in-app purchase，Product ID 建議用 `gomoku.remove_ads`。
2. 在 RevenueCat 建立 iOS App，Bundle ID 要和 Xcode 專案一致。
3. 在 RevenueCat Product Catalog 匯入或建立 `gomoku.remove_ads`。
4. 建立 entitlement：`remove_ads`。
5. 把 `gomoku.remove_ads` attach 到 `remove_ads` entitlement。
6. 建立 current/default offering，加入一個 package，package 內選 `gomoku.remove_ads`。
7. App 目前會讀 `offerings.current?.availablePackages.first`，所以 current offering 一定要有 package。

### 模擬器內購測試

專案已加入本機 StoreKit 設定檔：[GomokuApp/Resources/StoreKit/Gomoku.storekit](GomokuApp/Resources/StoreKit/Gomoku.storekit)。Xcode 的 `Gomoku` scheme 已指向這個檔案，Debug 跑模擬器時可直接測試 `gomoku.remove_ads`，不需要登入 Apple 帳號。

若 Xcode 仍跳出 Apple 帳號登入，請重新選一次：

1. Xcode 上方選單 `Product` > `Scheme` > `Edit Scheme...`
2. 左側選 `Run`
3. `Options` 分頁的 `StoreKit Configuration` 選 `Gomoku.storekit`
4. 停掉 App 後重新 Run

正式使用前請修改 [GomokuApp/AppConfig.swift](GomokuApp/AppConfig.swift)：

```swift
static let revenueCatAPIKey = "你的 RevenueCat public Apple API key"
static let removeAdsEntitlementID = "remove_ads"
```

App 內使用自訂 SwiftUI paywall：[GomokuApp/Views/RemoveAdsView.swift](GomokuApp/Views/RemoveAdsView.swift)。主畫面進入移除廣告頁、購買、恢復購買都會先通過親子鎖，通過後才呼叫 RevenueCat/Apple 購買流程。

參考：RevenueCat iOS installation、SDK configure、customer info、offerings、purchase docs
https://www.revenuecat.com/docs/getting-started/installation/ios  
https://www.revenuecat.com/docs/getting-started/configuring-sdk  
https://www.revenuecat.com/docs/customers/customer-info  
https://www.revenuecat.com/docs/offerings/overview
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
