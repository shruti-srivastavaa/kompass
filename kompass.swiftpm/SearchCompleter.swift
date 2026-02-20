import Combine

import MapKit

import SwiftUI

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = ""

    @Published var completions: [SearchResult] = []

    @Published var isOffline = false
    @Published var allLocations: [Location] = []  // Injected from ContentView

    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        completer.delegate = self

        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] newQuery in
                guard let self = self else { return }
                self.performOfflineSearch(query: newQuery)
            }
            .store(in: &cancellables)

        // React to offline mode changes (now always true)
        $isOffline
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.performOfflineSearch(query: self.query)
            }
            .store(in: &cancellables)
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    private func performOfflineSearch(query: String) {
        guard !query.isEmpty else {
            self.completions = []
            return
        }

        let lowerQuery = query.lowercased()
        let filtered = allLocations.filter { loc in
            loc.name.lowercased().contains(lowerQuery)
                || loc.description.lowercased().contains(lowerQuery)
        }

        self.completions = filtered.map { .offline($0) }
    }

    // MKLocalSearchCompleterDelegate methods removed as we are 100% offline
}
