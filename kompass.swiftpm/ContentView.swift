import SwiftUI
import MapKit

struct SimpleRouteStep: Identifiable, Hashable {
    let id = UUID()
    let instructions: String
}

struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )
    @State private var selectedLocation: Location?
    @State private var routeSteps: [SimpleRouteStep] = []
    @State private var showDirections = false
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var startLocation: Location?
    @State private var endLocation: Location?
    
    // Search - From
    @State private var fromText = ""
    @State private var fromResults: [MKMapItem] = []
    @State private var activeField: ActiveField? = nil
    
    // Search - To
    @State private var toText = ""
    @State private var toResults: [MKMapItem] = []
    
    enum ActiveField {
        case from, to
    }

    var body: some View {
        ZStack {
            // MARK: - Map
            MapView(
                region: $region,
                locations: allLocations,
                selectedLocation: $selectedLocation,
                routeCoordinates: $routeCoordinates
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // MARK: - From / To Search Bars
                VStack(spacing: 8) {
                    // FROM field
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        TextField("From: search location...", text: $fromText)
                            .autocorrectionDisabled()
                            .onTapGesture { activeField = .from }
                            .onChange(of: fromText) { newValue in
                                if activeField == .from {
                                    performSearch(query: newValue, isFrom: true)
                                }
                            }
                        if !fromText.isEmpty {
                            Button(action: {
                                fromText = ""
                                fromResults = []
                                startLocation = nil
                                clearRouteIfNeeded()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    // TO field
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        TextField("To: search destination...", text: $toText)
                            .autocorrectionDisabled()
                            .onTapGesture { activeField = .to }
                            .onChange(of: toText) { newValue in
                                if activeField == .to {
                                    performSearch(query: newValue, isFrom: false)
                                }
                            }
                        if !toText.isEmpty {
                            Button(action: {
                                toText = ""
                                toResults = []
                                endLocation = nil
                                clearRouteIfNeeded()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .padding(12)
                .background(Color.white.opacity(0.95))
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // MARK: - Search Results Dropdown
                let activeResults = activeField == .from ? fromResults : toResults
                let activeText = activeField == .from ? fromText : toText
                
                if !activeResults.isEmpty && !activeText.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(activeResults, id: \.self) { item in
                                Button(action: {
                                    selectSearchResult(item)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name ?? "Unknown")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        if let address = item.placemark.title {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // MARK: - Navigate Button (when both are set)
                if startLocation != nil && endLocation != nil && routeCoordinates.isEmpty {
                    Button(action: {
                        calculateRoute()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            Text("Get Directions")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // MARK: - Route Controls
                if !routeCoordinates.isEmpty {
                    HStack {
                        Button("Clear Route") {
                            startLocation = nil
                            endLocation = nil
                            routeCoordinates = []
                            routeSteps = []
                            selectedLocation = nil
                            fromText = ""
                            toText = ""
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Show Directions") {
                            showDirections = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 8)
                }
            }
            
            // MARK: - Zoom Buttons (top-right)
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button(action: zoomIn) {
                            Image(systemName: "plus.magnifyingglass")
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        Button(action: zoomOut) {
                            Image(systemName: "minus.magnifyingglass")
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding(.trailing)
                    .padding(.top, 130)
                }
                Spacer()
            }
        }
        .sheet(item: $selectedLocation) { location in
            LocationDetailView(location: location)
        }
        .sheet(isPresented: $showDirections) {
            NavigationView {
                List {
                    ForEach(routeSteps) { step in
                        Text(step.instructions)
                    }
                    
                    Button("Open in Apple Maps") {
                        openInMaps()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .navigationTitle("Directions")
                .toolbar {
                    Button("Done") {
                        showDirections = false
                    }
                }
            }
        }
    }
    
    // Combine sample data with searched locations for map display
    var allLocations: [Location] {
        var locs = Location.sampleData
        if let s = startLocation, !locs.contains(where: { $0.name == s.name }) {
            locs.append(s)
        }
        if let e = endLocation, !locs.contains(where: { $0.name == e.name }) {
            locs.append(e)
        }
        return locs
    }
    
    func clearRouteIfNeeded() {
        routeCoordinates = []
        routeSteps = []
    }
    
    // MARK: - Search
    func performSearch(query: String, isFrom: Bool) {
        guard !query.isEmpty else {
            if isFrom { fromResults = [] } else { toResults = [] }
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            DispatchQueue.main.async {
                if isFrom {
                    self.fromResults = response.mapItems
                } else {
                    self.toResults = response.mapItems
                }
            }
        }
    }
    
    func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        let name = item.name ?? "Unknown"
        
        let location = Location(
            name: name,
            coordinate: coordinate,
            description: item.placemark.title ?? "",
            iconName: "mappin.circle.fill"
        )
        
        // Fly to the location
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        if activeField == .from {
            startLocation = location
            fromText = name
            fromResults = []
        } else {
            endLocation = location
            toText = name
            toResults = []
        }
        
        activeField = nil
    }
    
    // MARK: - Route
    func calculateRoute() {
        guard let start = startLocation, let end = endLocation else { return }
        
        let startPlacemark = MKPlacemark(coordinate: start.coordinate)
        let endPlacemark = MKPlacemark(coordinate: end.coordinate)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: startPlacemark)
        directionRequest.destination = MKMapItem(placemark: endPlacemark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate { response, error in
            guard let response = response else {
                if let error = error {
                    print("Error getting directions: \(error.localizedDescription)")
                }
                return
            }
            
            if let route = response.routes.first {
                let pointCount = route.polyline.pointCount
                var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
                route.polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
                
                let steps = route.steps.map { SimpleRouteStep(instructions: $0.instructions) }
                
                DispatchQueue.main.async {
                    self.routeCoordinates = coordinates
                    self.routeSteps = steps
                }
            }
        }
    }
    
    // MARK: - Open in Maps
    func openInMaps() {
        guard let start = startLocation, let end = endLocation else { return }
        
        let startPlacemark = MKPlacemark(coordinate: start.coordinate)
        let endPlacemark = MKPlacemark(coordinate: end.coordinate)
        
        let startItem = MKMapItem(placemark: startPlacemark)
        startItem.name = start.name
        
        let endItem = MKMapItem(placemark: endPlacemark)
        endItem.name = end.name
        
        MKMapItem.openMaps(with: [startItem, endItem], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    // MARK: - Zoom
    func zoomIn() {
        var newSpan = region.span
        newSpan.latitudeDelta *= 0.5
        newSpan.longitudeDelta *= 0.5
        region.span = newSpan
    }
    
    func zoomOut() {
        var newSpan = region.span
        newSpan.latitudeDelta *= 2.0
        newSpan.longitudeDelta *= 2.0
        region.span = newSpan
    }
}
