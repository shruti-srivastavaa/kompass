import SwiftUI
import WidgetKit
import ActivityKit

struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NavigationAttributes.self) { context in
            // Lock Screen / Banner UI
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                    Text(context.state.currentInstruction)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatETA(context.state.etaSeconds))
                        .font(.custom("Menlo", size: 14).bold())
                        .foregroundColor(.green)
                }
                
                HStack {
                    if let next = context.state.nextInstruction {
                        Text("Then: \(next)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(formatDistance(context.state.distanceMeters))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(white: 0.2))
                        Capsule().fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(context.state.stepIndex + 1) / CGFloat(max(context.state.totalSteps, 1)))
                    }
                }
                .frame(height: 4)
                .padding(.top, 4)
            }
            .padding()
            .background(Color.black)
            .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: turnIcon(for: context.state.currentInstruction))
                        .font(.title2.bold())
                        .foregroundColor(.green)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.currentInstruction)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let next = context.state.nextInstruction {
                            Text("Then: \(next)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(white: 0.6))
                        }
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(white: 0.2))
                                Capsule().fill(Color.green)
                                    .frame(width: max(0, geo.size.width * CGFloat(context.state.stepIndex + 1) / CGFloat(max(context.state.totalSteps, 1))))
                            }
                        }
                        .frame(height: 5)
                        .padding(.top, 4)
                        
                        HStack {
                            Text(formatDistance(context.state.distanceMeters))
                                .font(.caption2.bold())
                                .foregroundColor(.gray)
                            Spacer()
                            Text(formatETA(context.state.etaSeconds))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: turnIcon(for: context.state.currentInstruction))
                        .foregroundColor(.green)
                        .font(.system(size: 12, weight: .bold))
                    Text(abbreviateInstruction(context.state.currentInstruction))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                Text(formatETA(context.state.etaSeconds))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            } minimal: {
                Image(systemName: turnIcon(for: context.state.currentInstruction))
                    .foregroundColor(.green)
            }
            .keylineTint(.green)
        }
    }
    
    private func formatETA(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        if mins < 1 { return "<1m" }
        if mins < 60 { return "\(mins)m" }
        return "\(mins/60)h \(mins%60)m"
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    private func turnIcon(for instruction: String) -> String {
        let lower = instruction.lowercased()
        if lower.contains("direct") { return "arrow.up" }
        if lower.contains("right") { return "arrow.turn.up.right" }
        if lower.contains("left") { return "arrow.turn.up.left" }
        if lower.contains("u-turn") || lower.contains("u turn") { return "arrow.uturn.down" }
        if lower.contains("merge") { return "arrow.merge" }
        if lower.contains("exit") { return "arrow.up.right" }
        if lower.contains("destination") || lower.contains("arrive") { return "mappin.circle.fill" }
        return "arrow.up"
    }

    private func abbreviateInstruction(_ instruction: String) -> String {
        let abbr = instruction
            .replacingOccurrences(of: "Turn left", with: "L")
            .replacingOccurrences(of: "Turn right", with: "R")
            .replacingOccurrences(of: "Continue", with: "Cont")
            .replacingOccurrences(of: "destination", with: "dest", options: .caseInsensitive)
        return String(abbr.prefix(25)) + (abbr.count > 25 ? "..." : "")
    }
}
