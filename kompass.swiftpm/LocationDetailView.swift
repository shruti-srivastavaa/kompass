import SwiftUI

struct LocationDetailView: View {
    let location: Location
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: location.iconName)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .foregroundColor(.accentColor)
                .padding()
                .background(Circle().fill(Color.accentColor.opacity(0.1)))
            
            Text(location.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(location.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
