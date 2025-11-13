//
//  AdminDashboardView.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var adminViewModel = AdminViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Statistiques en temps réel
                ScrollView {
                    VStack(spacing: 20) {
                        // Statistiques principales
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            StatCard(
                                title: "Courses totales",
                                value: String(adminViewModel.totalRides),
                                icon: "car.fill",
                                color: .blue
                            )
                            StatCard(
                                title: "Revenus totaux",
                                value: "\(Int(adminViewModel.totalRevenue)) CDF",
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )
                            StatCard(
                                title: "Revenus aujourd'hui",
                                value: "\(Int(adminViewModel.todayRevenue)) CDF",
                                icon: "calendar", 
                                color: .orange
                            )
                            StatCard(
                                title: "Conducteurs actifs",
                                value: "\(adminViewModel.activeDriversCount)",
                                icon: "person.2.fill",
                                color: .purple
                            )
                        }
                        .padding()
                        
                        // Courses en cours
                        if !adminViewModel.activeRides.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Courses en cours")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(adminViewModel.activeRides.prefix(5)) { ride in
                                    ActiveRideRow(ride: ride)
                                }
                            }
                        }
                        
                        // Sections de gestion
                        VStack(spacing: 15) {
                            NavigationLink(destination: DriversManagementView()
                                .environmentObject(adminViewModel)) {
                                AdminMenuRow(title: "Gérer les conducteurs", icon: "person.badge.key.fill", color: .blue)
                            }
                            
                            NavigationLink(destination: RidesManagementView()
                                .environmentObject(adminViewModel)) {
                                AdminMenuRow(title: "Gérer les courses", icon: "list.bullet.rectangle.fill", color: .green)
                            }
                            
                            NavigationLink(destination: SupportView()) {
                                AdminMenuRow(title: "Support", icon: "questionmark.circle.fill", color: .orange)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Tableau de bord")
            .refreshable {
                adminViewModel.loadAllData()
            }
            .task {
                adminViewModel.loadAllData()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

struct AdminMenuRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

struct ActiveRideRow: View {
    let ride: Ride
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ride.pickupLocation.address ?? "Point de départ")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(ride.dropoffLocation.address ?? "Destination")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(ride.estimatedPrice)) CDF")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                StatusBadge(status: ride.status)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct DriversManagementView: View {
    @EnvironmentObject var adminViewModel: AdminViewModel
    
    var body: some View {
        List {
            Section("Conducteurs en ligne") {
                ForEach(adminViewModel.onlineDrivers) { driver in
                    DriverRow(driver: driver)
                }
            }
            
            Section("Tous les conducteurs") {
                ForEach(adminViewModel.allDrivers) { driver in
                    DriverRow(driver: driver)
                }
            }
        }
        .navigationTitle("Conducteurs")
        .refreshable {
            await adminViewModel.loadDrivers()
        }
    }
}

struct DriverRow: View {
    let driver: User
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.name)
                    .font(.headline)
                if let driverInfo = driver.driverInfo {
                    Text("Plaque: \(driverInfo.licensePlate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.accentOrange)
                            .font(.caption)
                        if let rating = driverInfo.rating {
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                        } else {
                            Text("0.0")
                                .font(.caption)
                        }
                    }
                }
            }
            
            Spacer()
            
            if driver.driverInfo?.isOnline ?? false {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RidesManagementView: View {
    @EnvironmentObject var adminViewModel: AdminViewModel
    @State private var selectedFilter: RideFilter = .all
    
    enum RideFilter: String, CaseIterable {
        case all = "Toutes"
        case active = "En cours"
        case completed = "Terminées"
        case cancelled = "Annulées"
    }
    
    var filteredRides: [Ride] {
        switch selectedFilter {
        case .all:
            return adminViewModel.allRides
        case .active:
            return adminViewModel.activeRides
        case .completed:
            return adminViewModel.completedRides
        case .cancelled:
            return adminViewModel.cancelledRides
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filtres
            Picker("Filtre", selection: $selectedFilter) {
                ForEach(RideFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Liste des courses
            List {
                ForEach(filteredRides) { ride in
                    NavigationLink(destination: RideDetailView(ride: ride)) {
                        RideRow(ride: ride)
                    }
                }
            }
        }
        .navigationTitle("Courses")
        .refreshable {
            await adminViewModel.loadRides()
        }
    }
}

struct RideRow: View {
    let ride: Ride
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ride.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                StatusBadge(status: ride.status)
            }
            
            Text(ride.pickupLocation.address ?? "Point de départ")
                .font(.subheadline)
                .lineLimit(1)
            
            Text(ride.dropoffLocation.address ?? "Destination")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Text("\(Int(ride.estimatedPrice)) CDF")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                Spacer()
                if let distance = ride.distance {
                    Text("\(String(format: "%.1f", distance)) km")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RideDetailView: View {
    let ride: Ride
    
    var body: some View {
        Form {
            Section("Informations") {
                HStack {
                    Text("Statut")
                    Spacer()
                    StatusBadge(status: ride.status)
                }
                
                HStack {
                    Text("Prix")
                    Spacer()
                    Text("\(Int(ride.finalPrice ?? ride.estimatedPrice)) CDF")
                        .foregroundColor(.orange)
                }
                
                if let distance = ride.distance {
                    HStack {
                        Text("Distance")
                        Spacer()
                        Text("\(String(format: "%.1f", distance)) km")
                    }
                }
            }
            
            Section("Point de départ") {
                Text(ride.pickupLocation.address ?? "N/A")
            }
            
            Section("Destination") {
                Text(ride.dropoffLocation.address ?? "N/A")
            }
            
            Section("Dates") {
                HStack {
                    Text("Créée le")
                    Spacer()
                    Text(ride.createdAt, style: .date)
                }
                
                if let startedAt = ride.startedAt {
                    HStack {
                        Text("Commencée le")
                        Spacer()
                        Text(startedAt, style: .date)
                    }
                }
                
                if let completedAt = ride.completedAt {
                    HStack {
                        Text("Terminée le")
                        Spacer()
                        Text(completedAt, style: .date)
                    }
                }
            }
        }
        .navigationTitle("Détails de la course")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportView: View {
    var body: some View {
        List {
            Text("Support et signalements")
        }
        .navigationTitle("Support")
    }
}

#Preview {
    AdminDashboardView()
}

