//
//  GoogleMapView.swift
//
        
//
//  Wrapper SwiftUI pour GMSMapView (remplace EnhancedMapView avec MapKit)
//

import SwiftUI
import MapKit
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(GoogleMaps)
import GoogleMaps
#endif

#if canImport(GoogleMaps)
// Classe pour stocker l'état de la carte (marqueurs et routes)
class MapState {
    var currentPolyline: GMSPolyline?
    var markers: [GMSMarker] = []
}
#endif

struct GoogleMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var pickupLocation: Location?
    var dropoffLocation: Location?
    let showsUserLocation: Bool
    var driverAnnotations: [DriverAnnotation] = []
    var availableDrivers: [User] = []
    var driverLocation: Location?
    var routePolyline: String? // Polyline encodée de la route
    let onLocationUpdate: ((Location) -> Void)?
    let onRegionChange: ((MKCoordinateRegion) -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        #if canImport(GoogleMaps)
        // Vérifier que le SDK est initialisé AVANT de créer la vue
        // Si ce n'est pas le cas, essayer d'initialiser immédiatement
        if !GoogleMapsService.shared.initialized {
            print("❌ ERREUR: Google Maps SDK n'est pas initialisé avant makeUIView")
            print("⚠️ GoogleMapView: Tentative d'initialisation d'urgence...")
            
            // Trouver la clé API
            var apiKey: String? = nil
            
            // Essayer depuis Info.plist
            if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
               !key.isEmpty, key != "YOUR_API_KEY_HERE" {
                apiKey = key
            }
            
            // Sinon, utiliser la clé de développement
            if apiKey == nil {
                apiKey = "AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8"
                print("⚠️ Utilisation de la clé API de développement (fallback)")
            }
            
            // Initialiser le SDK (de manière synchrone)
            if let key = apiKey {
                GoogleMapsService.shared.initialize(apiKey: key)
            }
            
            // Vérifier à nouveau
            if !GoogleMapsService.shared.initialized {
                print("❌ ERREUR CRITIQUE: Impossible d'initialiser Google Maps SDK")
                print("⚠️ Retour à MapKit (fallback)")
                let mapView = MKMapView()
                mapView.region = region
                mapView.showsUserLocation = showsUserLocation
                return mapView
            }
        }
        
        // Vérifier une dernière fois avant de créer GMSMapView
        guard GoogleMapsService.shared.initialized else {
            print("❌ ERREUR: Google Maps SDK toujours non initialisé")
            print("⚠️ Retour à MapKit (fallback)")
            let mapView = MKMapView()
            mapView.region = region
            mapView.showsUserLocation = showsUserLocation
            return mapView
        }
        
        print("✅ GoogleMapView: Utilisation de Google Maps (GMSMapView)")
        print("✅ SDK Google Maps initialisé et prêt")
        
        let camera = GMSCameraPosition.camera(
            withLatitude: region.center.latitude,
            longitude: region.center.longitude,
            zoom: Float(log2(360.0 / region.span.latitudeDelta))
        )
        
        // Utiliser l'ancienne méthode d'initialisation compatible avec toutes les versions
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = showsUserLocation
        mapView.settings.myLocationButton = false // On gère le bouton manuellement
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = false
        
        // Style de carte personnalisé (optionnel)
        // mapView.mapStyle = try? GMSMapStyle(contentsOfFileURL: styleURL)
        
        return mapView
        #else
        print("⚠️ GoogleMapView: Google Maps non disponible, utilisation de MapKit (fallback)")
        print("⚠️ Vérifiez que les packages Google Maps sont bien liés au target dans Xcode")
        
        // Fallback vers MapKit si Google Maps n'est pas disponible
        let mapView = MKMapView()
        mapView.region = region
        mapView.showsUserLocation = showsUserLocation
        return mapView
        #endif
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        #if canImport(GoogleMaps)
        guard let mapView = uiView as? GMSMapView else { return }
        
        // Récupérer ou créer l'état de la carte
        let state = context.coordinator.mapState
        
        // Mettre à jour la caméra si la région change significativement (seulement si pas de route)
        if routePolyline == nil {
            let currentCenter = mapView.camera.target
            let distance = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
                .distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
            
            // Ne mettre à jour la caméra que si le changement est significatif (> 100m)
            if distance > 100 {
                let camera = GMSCameraPosition.camera(
                    withLatitude: region.center.latitude,
                    longitude: region.center.longitude,
                    zoom: Float(log2(360.0 / max(region.span.latitudeDelta, 0.01)))
                )
                mapView.animate(to: camera)
            }
        }
        
        // Toujours mettre à jour la route et les marqueurs
        updateRoute(on: mapView, state: state)
        #else
        guard let mapView = uiView as? MKMapView else { return }
        mapView.region = region
        // Mettre à jour les annotations si nécessaire
        #endif
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    #if canImport(GoogleMaps)
    private func updateMarkers(on mapView: GMSMapView, state: MapState) {
        // Supprimer les anciens marqueurs
        for marker in state.markers {
            marker.map = nil
        }
        state.markers.removeAll()
        
        // Ajouter le marqueur de prise en charge
        if let pickup = pickupLocation {
            let pickupMarker = GMSMarker(position: pickup.coordinate)
            pickupMarker.title = "Point de départ"
            #if os(iOS)
            pickupMarker.icon = GMSMarker.markerImage(with: UIColor.systemGreen)
            #else
            pickupMarker.icon = GMSMarker.markerImage(with: .green)
            #endif
            pickupMarker.map = mapView
            state.markers.append(pickupMarker)
            print("📍 Marqueur pickup ajouté: \(pickup.latitude), \(pickup.longitude)")
        }
        
        // Ajouter le marqueur de destination
        if let dropoff = dropoffLocation {
            let dropoffMarker = GMSMarker(position: dropoff.coordinate)
            dropoffMarker.title = "Destination"
            #if os(iOS)
            dropoffMarker.icon = GMSMarker.markerImage(with: UIColor.systemRed)
            #else
            dropoffMarker.icon = GMSMarker.markerImage(with: .red)
            #endif
            dropoffMarker.map = mapView
            state.markers.append(dropoffMarker)
            print("📍 Marqueur destination ajouté: \(dropoff.latitude), \(dropoff.longitude)")
        }
        
        // Ajouter les marqueurs des chauffeurs disponibles
        for driver in availableDrivers {
            if let location = driver.driverInfo?.currentLocation {
                let driverMarker = GMSMarker(position: location.coordinate)
                driverMarker.title = driver.name
                #if os(iOS)
                driverMarker.icon = GMSMarker.markerImage(with: UIColor.systemOrange)
                #else
                driverMarker.icon = GMSMarker.markerImage(with: .orange)
                #endif
                driverMarker.map = mapView
                state.markers.append(driverMarker)
            }
        }
        
        // Ajouter les marqueurs des annotations de conducteurs (ancien format)
        for driver in driverAnnotations {
            let driverMarker = GMSMarker(position: driver.coordinate)
            driverMarker.title = "Chauffeur"
            #if os(iOS)
            driverMarker.icon = GMSMarker.markerImage(with: UIColor.systemOrange)
            #else
            driverMarker.icon = GMSMarker.markerImage(with: .orange)
            #endif
            driverMarker.map = mapView
            state.markers.append(driverMarker)
        }
        
        // Ajouter le marqueur du chauffeur assigné
        if let driverLoc = driverLocation {
            let assignedDriverMarker = GMSMarker(position: driverLoc.coordinate)
            assignedDriverMarker.title = "Votre chauffeur"
            #if os(iOS)
            assignedDriverMarker.icon = GMSMarker.markerImage(with: UIColor.systemBlue)
            #else
            assignedDriverMarker.icon = GMSMarker.markerImage(with: .blue)
            #endif
            assignedDriverMarker.map = mapView
            state.markers.append(assignedDriverMarker)
        }
    }
    
    private func updateRoute(on mapView: GMSMapView, state: MapState) {
        // Supprimer l'ancienne route si elle existe
        if let existingPolyline = state.currentPolyline {
            existingPolyline.map = nil
            state.currentPolyline = nil
        }
        
        guard let polylineString = routePolyline, !polylineString.isEmpty else {
            print("⚠️ GoogleMapView: Aucune route polyline fournie")
            // Afficher uniquement les marqueurs
            updateMarkers(on: mapView, state: state)
            return
        }
        
        print("🗺️ GoogleMapView: Mise à jour de la route")
        print("📍 Polyline reçue: \(polylineString.prefix(50))...")
        print("📍 Pickup: \(pickupLocation?.latitude ?? 0), \(pickupLocation?.longitude ?? 0)")
        print("📍 Dropoff: \(dropoffLocation?.latitude ?? 0), \(dropoffLocation?.longitude ?? 0)")
        
        // Décoder la polyline
        guard let path = GMSPath(fromEncodedPath: polylineString) else {
            print("❌ GoogleMapView: Impossible de décoder la polyline")
            updateMarkers(on: mapView, state: state)
            return
        }
        
        // Créer la polyline avec couleur orange
        let polyline = GMSPolyline(path: path)
        #if os(iOS)
        polyline.strokeColor = UIColor.systemOrange
        #else
        polyline.strokeColor = .orange
        #endif
        polyline.strokeWidth = 4.0
        polyline.map = mapView
        state.currentPolyline = polyline
        
        print("✅ GoogleMapView: Route affichée avec succès (path count: \(path.count()))")
        
        // Afficher les marqueurs
        updateMarkers(on: mapView, state: state)
        
        // Ajuster la caméra pour afficher toute la route et les marqueurs
        var bounds = GMSCoordinateBounds(path: path)
        
        // Inclure les marqueurs dans les bounds
        if let pickup = pickupLocation {
            bounds = bounds.includingCoordinate(pickup.coordinate)
        }
        if let dropoff = dropoffLocation {
            bounds = bounds.includingCoordinate(dropoff.coordinate)
        }
        
        let update = GMSCameraUpdate.fit(bounds, withPadding: 80.0)
        mapView.animate(with: update)
    }
    #endif
    
    #if canImport(GoogleMaps)
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        let mapState = MapState()
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            // Mettre à jour la région quand la caméra change (seulement si pas de route active)
            // Pour éviter les conflits avec l'ajustement automatique de la caméra pour la route
            if parent.routePolyline == nil {
                let newRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: position.target.latitude,
                        longitude: position.target.longitude
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 360.0 / pow(2.0, Double(position.zoom)),
                        longitudeDelta: 360.0 / pow(2.0, Double(position.zoom))
                    )
                )
                
                DispatchQueue.main.async {
                    self.parent.region = newRegion
                    self.parent.onRegionChange?(newRegion)
                }
            }
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            // Optionnel: Gérer les clics sur la carte
        }
    }
    #else
    class Coordinator: NSObject {
        var parent: GoogleMapView
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
    }
    #endif
}

// Extension pour convertir MKCoordinateRegion en zoom level
extension MKCoordinateRegion {
    var zoomLevel: Float {
        return Float(log2(360.0 / span.latitudeDelta))
    }
}


