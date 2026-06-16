import SwiftUI

#if os(iOS)
import UIKit
#endif

struct VictoryCelebrationOverlay: View {
    let winner: Stone

    @State private var launched = false
    @State private var pulsing = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<86, id: \.self) { index in
                    VictoryParticle(index: index, launched: launched, size: proxy.size)
                }

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(VictoryTheme.sunny.opacity(0.26))
                            .frame(width: 122, height: 122)
                            .scaleEffect(pulsing ? 1.12 : 0.92)
                            .opacity(pulsing ? 0.32 : 0.72)

                        Image("GomokuMascots")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 122, height: 92)
                            .accessibilityHidden(true)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(VictoryTheme.sunny)
                            .offset(x: 26, y: -52)
                            .rotationEffect(.degrees(pulsing ? 10 : -8))
                    }

                    Text("\(winner.displayName)大勝利")
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundStyle(VictoryTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("五連珠完成")
                        Image(systemName: "sparkles")
                    }
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(VictoryTheme.berry)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.96),
                                    VictoryTheme.marshmallow.opacity(0.92),
                                    VictoryTheme.mint.opacity(0.52)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [VictoryTheme.sunny, VictoryTheme.berry.opacity(0.36), .white.opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: VictoryTheme.berry.opacity(0.22), radius: 24, x: 0, y: 14)
                .scaleEffect(launched ? 1 : 0.58)
                .opacity(launched ? 1 : 0)
                .position(x: proxy.size.width / 2, y: min(proxy.size.height * 0.29, 260))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.64)) {
                    launched = true
                }
                withAnimation(.easeInOut(duration: 0.62).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct EncouragementCelebrationOverlay: View {
    @State private var launched = false
    @State private var pulsing = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<58, id: \.self) { index in
                    EncouragementParticle(index: index, launched: launched, size: proxy.size)
                }

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(VictoryTheme.mint.opacity(0.22))
                            .frame(width: 116, height: 116)
                            .scaleEffect(pulsing ? 1.10 : 0.94)
                            .opacity(pulsing ? 0.36 : 0.72)

                        Image("GomokuMascots")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 116, height: 88)
                            .accessibilityHidden(true)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(VictoryTheme.berry)
                            .offset(x: 30, y: -48)
                            .scaleEffect(pulsing ? 1.12 : 0.92)
                    }

                    Text("差一點點")
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundStyle(VictoryTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("每一步都在變強")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(VictoryTheme.berry)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("再挑戰一局")
                        Image(systemName: "star.fill")
                    }
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(VictoryTheme.mint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.97),
                                    VictoryTheme.marshmallow.opacity(0.92),
                                    VictoryTheme.sunny.opacity(0.30),
                                    VictoryTheme.mint.opacity(0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [VictoryTheme.mint.opacity(0.70), VictoryTheme.sunny.opacity(0.70), .white.opacity(0.94)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: VictoryTheme.mint.opacity(0.22), radius: 24, x: 0, y: 14)
                .scaleEffect(launched ? 1 : 0.62)
                .opacity(launched ? 1 : 0)
                .position(x: proxy.size.width / 2, y: min(proxy.size.height * 0.29, 260))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
                    launched = true
                }
                withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}

enum CelebrationHaptics {
    @MainActor
    static func playWin() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred(intensity: 0.9)
        #endif
    }

    @MainActor
    static func playEncouragement() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred(intensity: 0.55)
        #endif
    }
}

private struct VictoryParticle: View {
    let index: Int
    let launched: Bool
    let size: CGSize

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: particleSize, weight: .heavy))
            .foregroundStyle(color)
            .rotationEffect(.degrees(launched ? endRotation : startRotation))
            .scaleEffect(launched ? endScale : 0.45)
            .opacity(launched ? endOpacity : 0)
            .position(startPosition)
            .offset(x: launched ? travelX : 0, y: launched ? travelY : 0)
            .animation(.easeOut(duration: duration).delay(delay), value: launched)
    }

    private var startPosition: CGPoint {
        CGPoint(
            x: size.width * (0.14 + normalized((index * 37) % 73) * 0.72),
            y: size.height * (0.22 + normalized((index * 19) % 31) * 0.16)
        )
    }

    private var travelX: CGFloat {
        let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
        return direction * size.width * (0.05 + normalized((index * 11) % 23) * 0.22)
    }

    private var travelY: CGFloat {
        size.height * (0.22 + normalized((index * 17) % 41) * 0.56)
    }

    private var particleSize: CGFloat {
        12 + normalized((index * 7) % 29) * 22
    }

    private var delay: Double {
        Double(index % 18) * 0.018
    }

    private var duration: Double {
        1.15 + Double(index % 13) * 0.055
    }

    private var startRotation: Double {
        Double((index * 17) % 360)
    }

    private var endRotation: Double {
        startRotation + Double(index.isMultiple(of: 2) ? -220 : 260)
    }

    private var endScale: CGFloat {
        0.72 + normalized((index * 5) % 17) * 0.64
    }

    private var endOpacity: Double {
        0.18 + Double((index * 3) % 7) * 0.10
    }

    private var symbol: String {
        ["star.fill", "heart.fill", "sparkles", "seal.fill", "circle.fill", "diamond.fill"][index % 6]
    }

    private var color: Color {
        [VictoryTheme.berry, VictoryTheme.sunny, VictoryTheme.mint, VictoryTheme.sky, VictoryTheme.lavender, VictoryTheme.coral][index % 6]
    }

    private func normalized(_ value: Int) -> CGFloat {
        CGFloat(value) / 100.0
    }
}

private struct EncouragementParticle: View {
    let index: Int
    let launched: Bool
    let size: CGSize

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: particleSize, weight: .heavy))
            .foregroundStyle(color)
            .rotationEffect(.degrees(launched ? endRotation : startRotation))
            .scaleEffect(launched ? endScale : 0.52)
            .opacity(launched ? endOpacity : 0)
            .position(startPosition)
            .offset(x: launched ? driftX : 0, y: launched ? liftY : 0)
            .animation(.easeOut(duration: duration).delay(delay), value: launched)
    }

    private var startPosition: CGPoint {
        CGPoint(
            x: size.width * (0.18 + normalized((index * 31) % 65) * 0.70),
            y: size.height * (0.50 + normalized((index * 13) % 30) * 0.28)
        )
    }

    private var driftX: CGFloat {
        let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
        return direction * size.width * (0.03 + normalized((index * 7) % 22) * 0.16)
    }

    private var liftY: CGFloat {
        -size.height * (0.16 + normalized((index * 19) % 34) * 0.30)
    }

    private var particleSize: CGFloat {
        12 + normalized((index * 9) % 24) * 18
    }

    private var delay: Double {
        Double(index % 16) * 0.024
    }

    private var duration: Double {
        1.25 + Double(index % 12) * 0.065
    }

    private var startRotation: Double {
        Double((index * 23) % 360)
    }

    private var endRotation: Double {
        startRotation + Double(index.isMultiple(of: 2) ? -72 : 86)
    }

    private var endScale: CGFloat {
        0.80 + normalized((index * 5) % 18) * 0.42
    }

    private var endOpacity: Double {
        0.20 + Double((index * 5) % 7) * 0.09
    }

    private var symbol: String {
        ["heart.fill", "star.fill", "sparkles", "lightbulb.fill", "circle.fill"][index % 5]
    }

    private var color: Color {
        [VictoryTheme.berry, VictoryTheme.sunny, VictoryTheme.mint, VictoryTheme.sky, VictoryTheme.lavender][index % 5]
    }

    private func normalized(_ value: Int) -> CGFloat {
        CGFloat(value) / 100.0
    }
}

private enum VictoryTheme {
    static let ink = Color(red: 0.18, green: 0.17, blue: 0.30)
    static let berry = Color(red: 0.91, green: 0.25, blue: 0.48)
    static let coral = Color(red: 1.00, green: 0.48, blue: 0.36)
    static let sunny = Color(red: 1.00, green: 0.78, blue: 0.24)
    static let mint = Color(red: 0.27, green: 0.78, blue: 0.62)
    static let sky = Color(red: 0.30, green: 0.67, blue: 0.94)
    static let lavender = Color(red: 0.60, green: 0.50, blue: 0.94)
    static let marshmallow = Color(red: 1.00, green: 0.91, blue: 0.96)
}
