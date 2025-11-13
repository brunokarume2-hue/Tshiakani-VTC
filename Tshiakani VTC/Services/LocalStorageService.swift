//
//  LocalStorageService.swift
//  Tshiakani VTC
//
//  Created by Admin on 08/11/2025.
//

import Foundation

/// Service de stockage local simple (sans Firebase)
/// Utilise UserDefaults pour stocker les données en local
class LocalStorageService {
    static let shared = LocalStorageService()
    
    private let usersKey = "TshiakaniVTC_users"
    private let ridesKey = "TshiakaniVTC_rides"
    
    private init() {}
    
    // MARK: - Users
    
    func saveUser(_ user: User) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        } else {
            users.append(user)
        }
        saveUsers(users)
    }
    
    func getUser(id: String) -> User? {
        let users = getAllUsers()
        return users.first { $0.id == id }
    }
    
    func getAllUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    private func saveUsers(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    // MARK: - Rides
    
    func saveRide(_ ride: Ride) {
        var rides = getAllRides()
        if let index = rides.firstIndex(where: { $0.id == ride.id }) {
            rides[index] = ride
        } else {
            rides.append(ride)
        }
        saveRides(rides)
    }
    
    func getRide(id: String) -> Ride? {
        let rides = getAllRides()
        return rides.first { $0.id == id }
    }
    
    func getRides(for userId: String) -> [Ride] {
        let rides = getAllRides()
        return rides.filter { $0.clientId == userId || $0.driverId == userId }
    }
    
    func getAllRides() -> [Ride] {
        guard let data = UserDefaults.standard.data(forKey: ridesKey),
              let rides = try? JSONDecoder().decode([Ride].self, from: data) else {
            return []
        }
        return rides
    }
    
    private func saveRides(_ rides: [Ride]) {
        if let data = try? JSONEncoder().encode(rides) {
            UserDefaults.standard.set(data, forKey: ridesKey)
        }
    }
    
    // MARK: - Méthodes génériques
    
    /// Récupère une valeur depuis UserDefaults
    func get(key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }
    
    /// Sauvegarde une valeur dans UserDefaults
    func set(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    /// Supprime une valeur de UserDefaults
    func remove(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

