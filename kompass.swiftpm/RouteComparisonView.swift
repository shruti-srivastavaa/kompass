import SwiftUI
import MapKit

/// A single route option returned from MKDirections or ride-share estimation
struct RouteOption: Identifiable {
    let id = UUID()
    let mode: ExtendedTransportMode
    let travelTime: TimeInterval
    let distance: CLLocationDistance
    let steps: [SimpleRouteStep]
    let polylineCoords: [CLLocationCoordinate2D]
    var fareEstimate: String?
    var isSelected: Bool = false
}

/// Extended transport modes covering all travel methods
enum ExtendedTransportMode: String, CaseIterable, Identifiable {
    case drive = "Drive"
    case walk = "Walk"
    case transit = "Transit"
    case cycle = "Cycle"
    case uber = "Uber"
    case lyft = "Lyft"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .drive: return "car.fill"
        case .walk: return "figure.walk"
        case .transit: return "bus.fill"
        case .cycle: return "bicycle"
        case .uber: return "car.side.front.open"
        case .lyft: return "car.side"
        }
    }
    
    var color: Color {
        switch self {
        case .drive: return .blue
        case .walk: return .green
        case .transit: return .orange
        case .cycle: return .teal
        case .uber: return .primary
        case .lyft: return .pink
        }
    }
    
    var mkTransportType: MKDirectionsTransportType? {
        switch self {
        case .drive: return .automobile
        case .walk: return .walking
        case .transit: return .transit
        case .cycle: return .walking // MK doesn't have cycling, approximate with walking
        case .uber, .lyft: return nil // ride-share — no MK route
        }
    }
    
    var isRideShare: Bool {
        self == .uber || self == .lyft
    }
    
    var isNativeRoute: Bool {
        [.drive, .walk, .transit].contains(self)
    }
}

// MARK: - Route Comparison View

struct RouteComparisonView: View {
    let routeOptions: [RouteOption]
    let onSelectRoute: (RouteOption) -> Void
    let onOpenRideShare: (ExtendedTransportMode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Routes")
                .font(.headline)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(routeOptions) { option in
                        routeCard(option)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    @ViewBuilder
    private func routeCard(_ option: RouteOption) -> some View {
        let isFastest = option.travelTime == routeOptions.filter({ !$0.mode.isRideShare }).map({ $0.travelTime }).min()
        
        Button {
            if option.mode.isRideShare {
                onOpenRideShare(option.mode)
            } else {
                onSelectRoute(option)
            }
        } label: {
            VStack(spacing: 10) {
                // Mode Icon
                ZStack {
                    Circle()
                        .fill(option.mode.color.opacity(option.isSelected ? 1 : 0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: option.mode.icon)
                        .font(.system(size: 20))
                        .foregroundColor(option.isSelected ? .white : option.mode.color)
                }
                
                // Mode name
                Text(option.mode.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                // ETA
                Text(formatDuration(option.travelTime))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isFastest ? .green : .primary)
                
                // Distance
                Text(formatDist(option.distance))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Fare or label
                if let fare = option.fareEstimate {
                    Text(fare)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(option.mode.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(option.mode.color.opacity(0.1))
                        .clipShape(Capsule())
                } else if option.mode.isRideShare {
                    Text("Open App")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(option.isSelected ? option.mode.color.opacity(0.08) : Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(option.isSelected ? option.mode.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? ""
    }
    
    private func formatDist(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}
