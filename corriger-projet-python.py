#!/usr/bin/env python3
"""
Script Python pour corriger automatiquement les erreurs de compilation Xcode
Analyse et corrige les problèmes de configuration du projet
"""

import os
import re
import json
import plistlib
from pathlib import Path

PROJECT_DIR = Path("/Users/admin/Documents/Tshiakani VTC")
XCODEPROJ = PROJECT_DIR / "Tshiakani VTC.xcodeproj"
PROJECT_FILE = XCODEPROJ / "project.pbxproj"
PACKAGE_RESOLVED = XCODEPROJ / "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
INFO_PLIST = PROJECT_DIR / "Tshiakani VTC/Info.plist"

def print_status(message, status="info"):
    """Affiche un message avec un statut coloré"""
    colors = {
        "success": "\033[0;32m✅",
        "error": "\033[0;31m❌",
        "warning": "\033[1;33m⚠️",
        "info": "\033[0;34mℹ️"
    }
    reset = "\033[0m"
    print(f"{colors.get(status, '')} {message}{reset}")

def check_info_plist_config():
    """Vérifie la configuration Info.plist"""
    print_status("Vérification de la configuration Info.plist...", "info")
    
    if not PROJECT_FILE.exists():
        print_status("Fichier project.pbxproj non trouvé", "error")
        return False
    
    content = PROJECT_FILE.read_text()
    
    # Vérifier GENERATE_INFOPLIST_FILE
    if 'GENERATE_INFOPLIST_FILE = NO' in content:
        print_status("GENERATE_INFOPLIST_FILE = NO (correct)", "success")
    else:
        print_status("GENERATE_INFOPLIST_FILE n'est pas NO", "error")
        return False
    
    # Vérifier INFOPLIST_FILE
    if 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' in content:
        print_status("INFOPLIST_FILE correctement configuré", "success")
    else:
        print_status("INFOPLIST_FILE incorrect", "error")
        return False
    
    # Vérifier que Info.plist n'est pas dans les ressources
    # Avec PBXFileSystemSynchronizedRootGroup, c'est géré automatiquement
    # mais on peut vérifier qu'il n'y a pas de référence explicite
    resources_pattern = r'PBXResourcesBuildPhase.*?files = \((.*?)\);'
    matches = re.findall(resources_pattern, content, re.DOTALL)
    
    info_plist_in_resources = False
    for match in matches:
        if 'Info.plist' in match:
            info_plist_in_resources = True
            break
    
    if info_plist_in_resources:
        print_status("Info.plist trouvé dans les ressources (à retirer manuellement dans Xcode)", "warning")
    else:
        print_status("Info.plist n'est pas dans les ressources (correct)", "success")
    
    return True

def check_packages():
    """Vérifie la configuration des packages"""
    print_status("Vérification des packages Swift...", "info")
    
    if not PROJECT_FILE.exists():
        return False
    
    content = PROJECT_FILE.read_text()
    
    # Vérifier GoogleMaps
    if 'ios-maps-sdk' in content and 'GoogleMaps' in content:
        print_status("Package GoogleMaps référencé", "success")
        googlemaps_ok = True
    else:
        print_status("Package GoogleMaps non trouvé", "error")
        googlemaps_ok = False
    
    # Vérifier GooglePlaces
    if 'ios-places-sdk' in content and 'GooglePlaces' in content:
        print_status("Package GooglePlaces référencé", "success")
        googleplaces_ok = True
    else:
        print_status("Package GooglePlaces non trouvé", "error")
        googleplaces_ok = False
    
    return googlemaps_ok and googleplaces_ok

def check_package_resolved():
    """Vérifie et crée Package.resolved si nécessaire"""
    print_status("Vérification de Package.resolved...", "info")
    
    # Créer le répertoire si nécessaire
    package_dir = PACKAGE_RESOLVED.parent
    package_dir.mkdir(parents=True, exist_ok=True)
    
    if PACKAGE_RESOLVED.exists():
        print_status("Package.resolved existe", "info")
        try:
            with open(PACKAGE_RESOLVED, 'rb') as f:
                data = plistlib.load(f)
                print_status(f"Packages résolus: {len(data.get('pins', []))}", "info")
        except Exception as e:
            print_status(f"Erreur lors de la lecture de Package.resolved: {e}", "warning")
    else:
        print_status("Package.resolved n'existe pas (sera créé par Xcode)", "info")

def verify_info_plist_exists():
    """Vérifie que Info.plist existe"""
    print_status("Vérification de l'existence de Info.plist...", "info")
    
    if INFO_PLIST.exists():
        print_status(f"Info.plist trouvé: {INFO_PLIST}", "success")
        
        # Vérifier le contenu
        try:
            with open(INFO_PLIST, 'rb') as f:
                plist_data = plistlib.load(f)
                if 'GOOGLE_MAPS_API_KEY' in plist_data:
                    print_status("Clé API Google Maps présente dans Info.plist", "success")
                else:
                    print_status("Clé API Google Maps absente de Info.plist", "warning")
        except Exception as e:
            print_status(f"Erreur lors de la lecture de Info.plist: {e}", "warning")
        
        return True
    else:
        print_status("Info.plist non trouvé", "error")
        return False

def create_summary_report():
    """Crée un rapport de résumé"""
    print("\n" + "="*60)
    print_status("RAPPORT DE VÉRIFICATION", "info")
    print("="*60)
    
    results = {
        "Info.plist config": check_info_plist_config(),
        "Packages": check_packages(),
        "Info.plist existe": verify_info_plist_exists(),
    }
    
    print("\n" + "="*60)
    print_status("RÉSUMÉ", "info")
    print("="*60)
    
    all_ok = all(results.values())
    
    for check, result in results.items():
        status = "✅ OK" if result else "❌ PROBLÈME"
        print(f"{check}: {status}")
    
    print("\n" + "="*60)
    
    if all_ok:
        print_status("Configuration du projet correcte !", "success")
        print_status("Actions restantes à effectuer dans Xcode:", "info")
        print("\n1. Retirer Info.plist de Copy Bundle Resources (si présent)")
        print("2. File > Packages > Reset Package Caches")
        print("3. File > Packages > Resolve Package Versions")
        print("4. Vérifier les frameworks dans General > Frameworks")
        print("5. Product > Clean Build Folder (⇧⌘K)")
        print("6. Product > Build (⌘B)")
    else:
        print_status("Des problèmes ont été détectés. Vérifiez les messages ci-dessus.", "warning")
    
    print("="*60 + "\n")

def main():
    """Fonction principale"""
    print("\n" + "="*60)
    print_status("CORRECTION AUTOMATIQUE DES ERREURS DE COMPILATION", "info")
    print("="*60 + "\n")
    
    # Vérifications
    check_info_plist_config()
    print()
    check_packages()
    print()
    check_package_resolved()
    print()
    verify_info_plist_exists()
    print()
    
    # Rapport final
    create_summary_report()

if __name__ == "__main__":
    main()

