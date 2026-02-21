// MARK: - Dynamic Island Navigation Overlay
// Simulates Apple Maps-style Dynamic Island during navigation.
// Shows compact pill by default; expand on tap for detailed view.

import SwiftUI

struct DynamicIslandView: View {
    let currentInstruction: String
    let nextInstruction: String?
    let etaSeconds: TimeInterval
    let distanceMeters: Double
    let stepIndex: Int
    let totalSteps: Int
    var onTap: () -> Void = {}
    var onEndNavigation: () -> Void = {}

    @State private var isExpanded = false
    @State private var pulseArrow = false

    // Derive turn icon from instruction
    private var turnIcon: String {
        let lower = currentInstruction.lowercased()
        if lower.contains("direct") { return "arrow.up" }
        if lower.contains("right") { return "arrow.turn.up.right" }
        if lower.contains("left") { return "arrow.turn.up.left" }
        if lower.contains("u-turn") || lower.contains("u turn") { return "arrow.uturn.down" }
        if lower.contains("merge") { return "arrow.merge" }
        if lower.contains("exit") { return "arrow.up.right" }
        if lower.contains("destination") || lower.contains("arrive") { return "mappin.circle.fill" }
        return "arrow.up"
    }

    private var etaFormatted: String {
        let mins = Int(etaSeconds) / 60
        if mins < 1 { return "<1 min" }
        if mins < 60 { return "\(mins) min" }
        let h = mins / 60
        let m = mins % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    private var distFormatted: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters))m"
        }
        return String(format: "%.1f km", distanceMeters / 1000)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                if isExpanded {
                    expandedView
                } else {
                    compactView
                }
                Spacer()
            }
            // Push exactly down to the safe area edge where the physical notch sits
            .padding(.top, proxy.safeAreaInsets.top > 0 ? proxy.safeAreaInsets.top - 4 : 44)
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: isExpanded)
            .onAppear {
                pulseArrow = true
            }
        }
        .ignoresSafeArea(.all, edges: .top)
    }

    // MARK: - Compact Pill (sits inside the notch cutout)
    private var compactView: some View {
        HStack(spacing: 10) {
            // Turn arrow with pulse
            Image(systemName: turnIcon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.green)

            Text(abbreviateInstruction(currentInstruction))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            Text(etaFormatted)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        // Position
        .padding(.horizontal, 40)
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded = true
        }
    }

    // MARK: - Expanded View (drops down from notch)
    private var expandedView: some View {
        VStack(spacing: 8) {
            // Turn direction + instruction
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: turnIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentInstruction.isEmpty ? "Continue on route" : currentInstruction)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    if let next = nextInstruction, !next.isEmpty {
                        Text("Then: \(abbreviateInstruction(next))")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(white: 0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.2))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.green)
                        .frame(
                            width: geo.size.width * CGFloat(stepIndex + 1)
                                / CGFloat(max(totalSteps, 1)), height: 3
                        )
                        .animation(.spring(response: 0.4), value: stepIndex)
                }
            }
            .frame(height: 3)

            // Bottom row: ETA + Distance + Step + End
            HStack(spacing: 12) {
                HStack(spacing: 3) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                    Text(etaFormatted)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(white: 0.5))
                    Text(distFormatted)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(white: 0.6))
                }

                Text("\(stepIndex + 1)/\(totalSteps)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color(white: 0.4))

                Spacer()

                // End navigation
                Button {
                    onEndNavigation()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("End")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.7))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .padding(.top, 0)
        .onTapGesture {
            isExpanded = false
        }
    }

    private func abbreviateInstruction(_ text: String) -> String {
        let short =
            text
            .replacingOccurrences(of: "Turn ", with: "")
            .replacingOccurrences(of: "Continue on ", with: "On ")
            .replacingOccurrences(of: "Keep ", with: "")
            .replacingOccurrences(of: "Proceed to ", with: "To ")
        return String(short.prefix(28)) + (short.count > 28 ? "…" : "")
    }
}
