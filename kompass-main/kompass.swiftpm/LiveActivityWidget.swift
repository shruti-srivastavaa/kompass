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
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text(context.state.currentInstruction.prefix(20) + (context.state.currentInstruction.count > 20 ? "..." : ""))
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(formatETA(context.state.etaSeconds))
                            .font(.custom("Menlo", size: 16).bold())
                            .foregroundColor(.green)
                        Text(formatDistance(context.state.distanceMeters))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let next = context.state.nextInstruction {
                        Text("Then: \(next)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Progress
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(white: 0.2))
                            Capsule().fill(Color.green)
                                .frame(width: geo.size.width * CGFloat(context.state.stepIndex + 1) / CGFloat(max(context.state.totalSteps, 1)))
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            } compactLeading: {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                Text(formatETA(context.state.etaSeconds))
                    .font(.custom("Menlo", size: 12).bold())
                    .foregroundColor(.green)
            } minimal: {
                Image(systemName: "location.fill")
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
}
