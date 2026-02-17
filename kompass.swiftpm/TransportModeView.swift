import SwiftUI

struct TransportModeView: View {
    @Binding var selectedMode: ExtendedTransportMode
    var routeOptions: [RouteOption]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExtendedTransportMode.allCases) { mode in
                    let option = routeOptions.first(where: { $0.mode == mode })
                    modeChip(mode: mode, option: option)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func modeChip(mode: ExtendedTransportMode, option: RouteOption?) -> some View {
        let isSelected = selectedMode == mode
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedMode = mode
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .medium))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                    
                    if let opt = option {
                        Text(formatDuration(opt.travelTime))
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.8)
                    } else if mode.isRideShare {
                        Text(mode == .uber ? "Ride" : "Ride")
                            .font(.system(size: 10))
                            .opacity(0.7)
                    }
                }
            }
            .foregroundColor(isSelected ? .white : mode.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? mode.color : mode.color.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : mode.color.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}
