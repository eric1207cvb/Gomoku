import Foundation
import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

#if canImport(RevenueCat)
import RevenueCat
#endif

enum PurchaseState: Equatable {
    case idle
    case loading
    case unavailable(String)
    case failed(String)
    case purchased

    var message: String? {
        switch self {
        case .idle, .loading, .purchased:
            nil
        case let .unavailable(message), let .failed(message):
            message
        }
    }
}

@MainActor
final class MonetizationStore: ObservableObject {
    @Published private(set) var adsRemoved = false
    @Published private(set) var purchaseState: PurchaseState = .idle

    private var configured = false

    var shouldShowAds: Bool {
        !adsRemoved
    }

    func configure() {
        guard !configured else { return }
        configured = true
        configureAds()
        configurePurchases()
    }

    func refreshCustomerInfo() {
        #if canImport(RevenueCat)
        guard isRevenueCatReady else {
            purchaseState = .unavailable("尚未設定 RevenueCat API Key")
            return
        }

        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            Task { @MainActor in
                guard let self else { return }
                if let customerInfo {
                    self.apply(customerInfo: customerInfo)
                } else if let error {
                    self.purchaseState = .failed(error.localizedDescription)
                }
            }
        }
        #else
        purchaseState = .unavailable("RevenueCat SDK 尚未加入專案")
        #endif
    }

    func purchaseRemoveAds() {
        #if canImport(RevenueCat)
        guard isRevenueCatReady else {
            purchaseState = .unavailable("請先填入 RevenueCat API Key")
            return
        }

        purchaseState = .loading
        Purchases.shared.getOfferings { [weak self] offerings, error in
            guard let package = offerings?.current?.availablePackages.first else {
                Task { @MainActor in
                    self?.purchaseState = .failed(error?.localizedDescription ?? "RevenueCat offering 尚未設定")
                }
                return
            }

            Purchases.shared.purchase(package: package) { [weak self] _, customerInfo, error, userCancelled in
                Task { @MainActor in
                    guard let self else { return }
                    if let customerInfo {
                        self.apply(customerInfo: customerInfo)
                        self.purchaseState = self.adsRemoved ? .purchased : .idle
                    } else if userCancelled {
                        self.purchaseState = .idle
                    } else {
                        self.purchaseState = .failed(error?.localizedDescription ?? "購買失敗")
                    }
                }
            }
        }
        #else
        purchaseState = .unavailable("RevenueCat SDK 尚未加入專案")
        #endif
    }

    func restorePurchases() {
        #if canImport(RevenueCat)
        guard isRevenueCatReady else {
            purchaseState = .unavailable("請先填入 RevenueCat API Key")
            return
        }

        purchaseState = .loading
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            Task { @MainActor in
                guard let self else { return }
                if let customerInfo {
                    self.apply(customerInfo: customerInfo)
                    self.purchaseState = self.adsRemoved ? .purchased : .idle
                } else {
                    self.purchaseState = .failed(error?.localizedDescription ?? "恢復購買失敗")
                }
            }
        }
        #else
        purchaseState = .unavailable("RevenueCat SDK 尚未加入專案")
        #endif
    }

    private func configureAds() {
        #if canImport(GoogleMobileAds)
        let requestConfiguration = MobileAds.shared.requestConfiguration
        requestConfiguration.maxAdContentRating = .general
        requestConfiguration.tagForChildDirectedTreatment = true
        requestConfiguration.tagForUnderAgeOfConsent = true
        requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        MobileAds.shared.start()
        #endif
    }

    private func configurePurchases() {
        #if canImport(RevenueCat)
        guard isRevenueCatReady else {
            purchaseState = .unavailable("尚未設定 RevenueCat API Key")
            return
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
        refreshCustomerInfo()
        #endif
    }

    #if canImport(RevenueCat)
    private var isRevenueCatReady: Bool {
        !AppConfig.revenueCatAPIKey.isEmpty &&
        !AppConfig.revenueCatAPIKey.contains("REVENUECAT_PUBLIC")
    }

    private func apply(customerInfo: CustomerInfo) {
        adsRemoved = customerInfo.entitlements[AppConfig.removeAdsEntitlementID]?.isActive == true
    }
    #endif
}
