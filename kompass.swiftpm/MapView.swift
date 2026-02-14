import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var locations: [Location]
    @Binding var selectedLocation: Location?
    @Binding var routeCoordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)

        // Update annotations
        let currentAnnotations = mapView.annotations.compactMap { $0 as? LocationAnnotation }
        let newLocations = locations.filter { location in
            !currentAnnotations.contains { $0.location.id == location.id }
        }

        if !newLocations.isEmpty {
            mapView.addAnnotations(newLocations.map { LocationAnnotation(location: $0) })
        }
        
        // Update selection
        if let selected = selectedLocation {
             if let annotation = mapView.annotations.first(where: { ($0 as? LocationAnnotation)?.location.id == selected.id }) {
                 mapView.selectAnnotation(annotation, animated: true)
             }
        } else {
             mapView.selectedAnnotations = []
        }

        // Update polyline
        mapView.removeOverlays(mapView.overlays)
        if !routeCoordinates.isEmpty {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
             
             // Zoom to fit route
             let rect = polyline.boundingMapRect
             mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let locationAnnotation = annotation as? LocationAnnotation else { return nil }

            let identifier = "LocationAnnotation"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
                view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                view?.annotation = annotation
            }

            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
             if let locationAnnotation = view.annotation as? LocationAnnotation {
                 parent.selectedLocation = locationAnnotation.location
             }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
             parent.selectedLocation = nil
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
             // Handle accessory tap if needed
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

class LocationAnnotation: NSObject, MKAnnotation {
    let location: Location
    var coordinate: CLLocationCoordinate2D { location.coordinate }
    var title: String? { location.name }
    var subtitle: String? { location.description }

    init(location: Location) {
        self.location = location
    }
}
