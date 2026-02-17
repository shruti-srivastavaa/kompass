import SwiftUI
import MapKit

struct LocationDetailView: View {
    let location: Location
    var userLocation: CLLocation?
    var onDirections: () -> Void = {}
    var onClose: () -> Void = {}
    var onSave: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack(alignment: .top, spacing: 14) {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(location.categoryColor.gradient)
                                .frame(width: 52, height: 52)
                            Image(systemName: location.iconName)
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.title3.bold())
                                .lineLimit(2)
                            
                            if let category = location.category {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(category.color)
                                    .fontWeight(.medium)
                            }
                            
                            // Address
                            if let address = location.address, !address.isEmpty {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            } else if !location.description.isEmpty {
                                Text(location.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            // Distance + Open/Closed
                            HStack(spacing: 12) {
                                if let dist = location.formattedDistance {
                                    Label(dist, systemImage: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let isOpen = location.isOpen {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(isOpen ? Color.green : Color.red)
                                            .frame(width: 7, height: 7)
                                        Text(isOpen ? "Open" : "Closed")
                                            .font(.caption.bold())
                                            .foregroundColor(isOpen ? .green : .red)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Action Buttons Row (Apple Maps style)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Directions
                            ActionButton(
                                icon: "arrow.triangle.turn.up.right.diamond.fill",
                                label: "Directions",
                                color: .blue,
                                isPrimary: true,
                                action: onDirections
                            )
                            
                            // Call
                            if let phone = location.phoneNumber, !phone.isEmpty {
                                ActionButton(
                                    icon: "phone.fill",
                                    label: "Call",
                                    color: .green,
                                    action: {
                                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                            }
                            
                            // Save
                            ActionButton(
                                icon: "bookmark.fill",
                                label: "Save",
                                color: .orange,
                                action: onSave
                            )
                            
                            // Share
                            ActionButton(
                                icon: "square.and.arrow.up",
                                label: "Share",
                                color: .purple,
                                action: {
                                    let text = "\(location.name)\n\(location.address ?? location.description)"
                                    let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = scene.windows.first {
                                        window.rootViewController?.present(av, animated: true)
                                    }
                                }
                            )
                            
                            // Open in Maps
                            ActionButton(
                                icon: "map.fill",
                                label: "Apple Maps",
                                color: .mint,
                                action: {
                                    let placemark = MKPlacemark(coordinate: location.coordinate)
                                    let item = MKMapItem(placemark: placemark)
                                    item.name = location.name
                                    item.openInMaps(launchOptions: nil)
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    // Info Section
                    VStack(spacing: 12) {
                        if let address = location.address, !address.isEmpty {
                            InfoRow(icon: "mappin.and.ellipse", label: "Address", value: address)
                        }
                        
                        if let phone = location.phoneNumber, !phone.isEmpty {
                            InfoRow(icon: "phone", label: "Phone", value: phone)
                        }
                        
                        if let url = location.url {
                            InfoRow(icon: "globe", label: "Website", value: url.host ?? url.absoluteString)
                        }
                        
                        if let _ = location.rating {
                            // Rating row (placeholder for future use)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 48, height: 48)
                    .background(isPrimary ? color : color.opacity(0.12))
                    .foregroundColor(isPrimary ? .white : color)
                    .clipShape(Circle())
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .frame(width: 72)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
