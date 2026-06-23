import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

struct AdBannerSlot: View {
    @EnvironmentObject private var monetization: MonetizationStore

    var body: some View {
        if monetization.shouldShowAds {
            #if canImport(GoogleMobileAds)
            GeometryReader { geometry in
                let width = max(320, geometry.size.width)
                let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

                HStack {
                    Spacer(minLength: 0)
                    BannerViewContainer(adSize: adSize, adUnitID: AppConfig.admobBannerAdUnitID)
                        .frame(width: adSize.size.width, height: adSize.size.height)
                        .clipped()
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 72)
            .clipped()
            .background(.regularMaterial)
            #else
            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.body.weight(.semibold))
                Text("廣告區")
                    .font(.footnote.weight(.semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color(red: 0.91, green: 0.25, blue: 0.48))
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.95, blue: 0.80),
                        Color(red: 0.88, green: 0.97, blue: 0.95)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            #endif
        }
    }
}

#if canImport(GoogleMobileAds)
private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adSize = adSize
    }
}
#endif
