import Foundation
import CoreLocation

struct Location: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let description: String
    let iconName: String
}

extension Location {
    static let sampleData: [Location] = [
        Location(
            name: "Eiffel Tower",
            coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
            description: "A wrought-iron lattice tower on the Champ de Mars in Paris, France. It is named after the engineer Gustave Eiffel, whose company designed and built the tower.",
            iconName: "building.columns"
        ),
        Location(
            name: "Statue of Liberty",
            coordinate: CLLocationCoordinate2D(latitude: 40.6892, longitude: -74.0445),
            description: "A colossal neoclassical sculpture on Liberty Island in New York Harbor within New York City, in the United States.",
            iconName: "figure.stand"
        ),
        Location(
            name: "Sydney Opera House",
            coordinate: CLLocationCoordinate2D(latitude: -33.8568, longitude: 151.2153),
            description: "A multi-venue performing arts centre in Sydney. Located on the banks of the Sydney Harbour, it is often regarded as one of the 20th century's most famous and distinctive buildings.",
            iconName: "music.note.house"
        ),
        Location(
            name: "Taj Mahal",
            coordinate: CLLocationCoordinate2D(latitude: 27.1751, longitude: 78.0421),
            description: "An ivory-white marble mausoleum on the right bank of the river Yamuna in the Indian city of Agra.",
            iconName: "building"
        ),
        Location(
            name: "Machu Picchu",
            coordinate: CLLocationCoordinate2D(latitude: -13.1631, longitude: -72.5450),
            description: "A 15th-century Inca citadel, located in the Eastern Cordillera of southern Peru, on a 2,430-metre (7,970 ft) mountain ridge.",
            iconName: "mountain.2"
        )
    ]
}
