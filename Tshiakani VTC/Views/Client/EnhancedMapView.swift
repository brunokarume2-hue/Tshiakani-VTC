//
//  EnhancedMapView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI
import MapKit

struct EnhancedMapView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var pickupLocation: Location?
    let showsUserLocation: Bool
    let driverAnnotations: [DriverAnnotation]
    let onLocationUpdate: ((Location) -> Void)?
    let onRegionChange: ((MKCoordinateRegion) -> Void)?
    
    var body: some View {
        ZStack {
            Map {
                if showsUserLocation {
                    UserAnnotation()
                }
                
                ForEach(allAnnotations) { annotation in
                    Annotation("", coordinate: annotation.coordinate) {
                        if annotation.type == .pickup {
                            // Marqueur animé pour le point de prise en charge
                            AnimatedPickupMarker()
                        } else if annotation.type == .driver {
                            // Marqueur pour les conducteurs
                            DriverMarker()
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange { context in
                let newRegion = MKCoordinateRegion(
                    center: context.region.center,
                    span: context.region.span
                )
                region = newRegion
                onRegionChange?(newRegion)
            }
            .ignoresSafeArea()
            
            // Bouton centrer sur la position actuelle
            VStack {
                HStack {
                    Spacer()
                    if let pickup = pickupLocation {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                region = MKCoordinateRegion(
                                    center: pickup.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding()
                    }
                }
                Spacer()
            }
        }
        .onChange(of: pickupLocation) { _, newLocation in
            if let location = newLocation {
                onLocationUpdate?(location)
            }
        }
    }
    
    private var allAnnotations: [EnhancedMapAnnotationItem] {
        var annotations: [EnhancedMapAnnotationItem] = []
        
        // Ajouter le marqueur de prise en charge
        if let pickup = pickupLocation {
            annotations.append(EnhancedMapAnnotationItem(
                coordinate: pickup.coordinate,
                type: .pickup
            ))
        }
        
        // Ajouter les marqueurs des conducteurs
        annotations.append(contentsOf: driverAnnotations.map { driver in
            EnhancedMapAnnotationItem(
                coordinate: driver.coordinate,
                type: .driver
            )
        })
        
        return annotations
    }
}

// Marqueur animé pour le point de prise en charge
struct AnimatedPickupMarker: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Cercle pulsant externe
            Circle()
                .fill(Color.green.opacity(pulseOpacity))
                .frame(width: 50, height: 50)
                .scaleEffect(pulseScale)
            
            // Cercle pulsant moyen
            Circle()
                .fill(Color.green.opacity(pulseOpacity * 0.7))
                .frame(width: 40, height: 40)
                .scaleEffect(pulseScale * 0.9)
            
            // Cercle intérieur blanc
            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Icône de localisation
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 24))
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                pulseScale = 1.8
                pulseOpacity = 0.0
            }
        }
    }
}

// Marqueur pour les conducteurs
struct DriverMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "motorcycle")
                .foregroundColor(.white)
                .font(.system(size: 16))
                .padding(8)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Triangle()
                .fill(Color.orange)
                .frame(width: 8, height: 6)
                .offset(y: -2)
        }
    }
}

// Structure pour les annotations
struct EnhancedMapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
}

enum AnnotationType {
    case pickup, driver
}

#Preview {
    EnhancedMapView(
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )),
        pickupLocation: .constant(Location(latitude: -4.3276, longitude: 15.3136, address: "Kinshasa")),
        showsUserLocation: true,
        driverAnnotations: [],
        onLocationUpdate: nil,
        onRegionChange: nil
    )
}

