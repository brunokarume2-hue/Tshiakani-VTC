# 📊 Modèles Swift pour PostgreSQL/PostGIS

Ce document décrit les modèles Swift créés pour correspondre au schéma de base de données PostgreSQL/PostGIS.

## 🗂️ Structure des Modèles

### 1. Utilisateur (`Utilisateur.swift`)

Correspond à la table `utilisateurs` :

```swift
struct Utilisateur: Identifiable, Decodable {
    let id: Int                    // SERIAL PRIMARY KEY
    let role: RoleUtilisateur      // 'client' ou 'chauffeur'
    let email: String              // UNIQUE, NOT NULL
    let password_hash: String?      // NOT NULL (optionnel dans la réponse API)
}
```

**Enum `RoleUtilisateur`** :
- `.client` - Utilisateur client
- `.chauffeur` - Utilisateur chauffeur

**Propriétés calculées** :
- `estClient: Bool` - Vérifie si l'utilisateur est un client
- `estChauffeur: Bool` - Vérifie si l'utilisateur est un chauffeur

---

### 2. Chauffeur (`Chauffeur.swift`)

Correspond à la table `chauffeurs` :

```swift
struct Chauffeur: Identifiable, Decodable {
    let id: Int                    // SERIAL PRIMARY KEY
    let user_id: Int               // FOREIGN KEY vers utilisateurs(id)
    let localisation: Location      // GEOGRAPHY(Point, 4326) via PostGIS
    let statut: StatutChauffeur    // 'disponible', 'en_course', 'hors_ligne'
}
```

**Enum `StatutChauffeur`** :
- `.disponible` - Chauffeur disponible pour une course
- `.en_course` - Chauffeur actuellement en course
- `.hors_ligne` - Chauffeur hors ligne

**Propriétés calculées** :
- `coordinate: CLLocationCoordinate2D` - Pour MapKit
- `estDisponible: Bool` - Vérifie si le chauffeur est disponible
- `estEnCourse: Bool` - Vérifie si le chauffeur est en course

**Note** : La localisation PostGIS est automatiquement convertie en objet `Location` Swift avec les coordonnées [longitude, latitude].

---

### 3. Course (`Course.swift`)

Correspond à la table `courses` :

```swift
struct Course: Identifiable, Decodable {
    let id: Int                    // SERIAL PRIMARY KEY
    let client_id: Int             // FOREIGN KEY vers utilisateurs(id)
    let chauffeur_id: Int?         // FOREIGN KEY vers chauffeurs(id), nullable
    let depart_point: Location     // GEOGRAPHY(Point, 4326) - Point de prise en charge
    let arrivee_point: Location    // GEOGRAPHY(Point, 4326) - Destination
    let statut: StatutCourse       // Statut de la course
    let montant_estime: Double     // NUMERIC(10, 2)
}
```

**Enum `StatutCourse`** :
- `.demande` - Course demandée
- `.accepte` - Course acceptée par un chauffeur
- `.annule` - Course annulée
- `.completed` - Course terminée

**Propriétés calculées** :
- `departCoordinate: CLLocationCoordinate2D` - Pour MapKit
- `arriveeCoordinate: CLLocationCoordinate2D` - Pour MapKit
- `distance: Double` - Distance calculée entre départ et arrivée
- `estEnAttente: Bool`, `estAcceptee: Bool`, `estTerminee: Bool`, `estAnnulee: Bool`

---

### 4. Transaction (`Transaction.swift`)

Correspond à la table `transactions` :

```swift
struct Transaction: Identifiable, Decodable {
    let id: Int                    // SERIAL PRIMARY KEY
    let course_id: Int             // FOREIGN KEY vers courses(id), UNIQUE (1:1)
    let montant_final: Double      // NUMERIC(10, 2)
    let token_paiement: String    // Référence du prestataire (Stripe, etc.)
    let statut: StatutTransaction  // 'charged', 'failed', 'refunded'
}
```

**Enum `StatutTransaction`** :
- `.charged` - Paiement effectué avec succès
- `.failed` - Paiement échoué
- `.refunded` - Paiement remboursé

**Propriétés calculées** :
- `estPaye: Bool` - Vérifie si le paiement a réussi
- `aEchoue: Bool` - Vérifie si le paiement a échoué
- `estRembourse: Bool` - Vérifie si le paiement a été remboursé
- `montantFormate: String` - Montant formaté pour l'affichage

---

## 🔄 Décodage depuis l'API PostgreSQL/PostGIS

Tous les modèles implémentent `Decodable` et gèrent automatiquement :

1. **Conversion des types PostgreSQL** :
   - `SERIAL` → `Int`
   - `NUMERIC(10, 2)` → `Double`
   - `VARCHAR` → `String`

2. **Conversion PostGIS** :
   - `GEOGRAPHY(Point, 4326)` → `Location` Swift
   - Format PostGIS `[longitude, latitude]` → Format Swift `Location(latitude, longitude)`

3. **Validation des contraintes CHECK** :
   - Les enums valident automatiquement les valeurs autorisées
   - Erreurs de décodage si les valeurs ne correspondent pas

## 📝 Exemple d'utilisation

### Décoder une réponse API

```swift
// Exemple : Récupérer les chauffeurs disponibles
func fetchChauffeurs() async throws -> [Chauffeur] {
    let url = URL(string: "https://api.example.com/chauffeurs")!
    let (data, _) = try await URLSession.shared.data(from: url)
    
    let decoder = JSONDecoder()
    let chauffeurs = try decoder.decode([Chauffeur].self, from: data)
    
    return chauffeurs
}
```

### Utiliser avec MapKit

```swift
// Afficher les chauffeurs sur une carte
ForEach(chauffeurs) { chauffeur in
    MapAnnotation(coordinate: chauffeur.coordinate) {
        DriverMarker(chauffeur: chauffeur)
    }
}
```

### Filtrer par statut

```swift
// Filtrer les chauffeurs disponibles
let chauffeursDisponibles = chauffeurs.filter { $0.estDisponible }

// Filtrer les courses en attente
let coursesEnAttente = courses.filter { $0.estEnAttente }
```

## 🔗 Relations entre les modèles

```
Utilisateur (1) ──< Chauffeur (user_id)
Utilisateur (1) ──< Course (client_id)
Chauffeur (1) ──< Course (chauffeur_id)
Course (1) ──< Transaction (course_id) [UNIQUE - relation 1:1]
```

## ⚠️ Notes importantes

1. **Sécurité** : Le `password_hash` n'est jamais décodé depuis l'API pour des raisons de sécurité
2. **PostGIS** : Les coordonnées PostGIS utilisent `[longitude, latitude]` mais sont converties en `Location(latitude, longitude)` pour Swift
3. **Validation** : Tous les enums valident les valeurs et lancent des erreurs de décodage si invalides
4. **Nullable** : Les champs optionnels (`?`) correspondent aux colonnes nullable dans PostgreSQL

## 🚀 Prochaines étapes

Pour utiliser ces modèles avec votre API :

1. Assurez-vous que votre API backend retourne les données au format JSON compatible
2. Utilisez `JSONDecoder` pour décoder les réponses
3. Intégrez avec `DriversService` pour récupérer les chauffeurs
4. Utilisez avec `MapKit` pour afficher les localisations

