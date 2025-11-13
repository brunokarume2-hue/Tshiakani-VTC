#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour remplacer toutes les références à l'ancien nom dans le projet
"""

import os
import re
from pathlib import Path

# Anciens noms et leurs remplacements
REPLACEMENTS = {
    "Tshiakani VTC": "Tshiakani VTC",
    "TshiakaniVTC": "TshiakaniVTC",
    "tshiakaniVTC": "tshiakaniVTC",
    "TSHIAKANI_VTC": "TSHIAKANI_VTC",
    "tshiakanivtc": "tshiakanivtc",
    "tshiakani-vtc": "tshiakani-vtc",
    "optimacode.com.tshiakani-vtc": "com.bruno.tshiakaniVTC",
    "optimacode.com.tshiakani-vtcTests": "com.bruno.tshiakaniVTCTests",
    "optimacode.com.tshiakani-vtcUITests": "com.bruno.tshiakaniVTCUITests",
    "tshiakanivtc.com": "tshiakanivtc.com",
    "support@tshiakanivtc.com": "support@tshiakanivtc.com",
}

# Dossiers à exclure
EXCLUDE_DIRS = {
    "Pods", "build", ".git", "node_modules", "DerivedData",
    ".build", ".swiftpm", "xcuserdata", ".DS_Store"
}

# Extensions de fichiers à traiter
INCLUDE_EXTENSIONS = {
    ".swift", ".m", ".h", ".mm", ".pbxproj", ".plist", ".xcconfig",
    ".json", ".js", ".jsx", ".ts", ".tsx", ".py", ".sh", ".yaml", ".yml",
    ".txt", ".xml", ".html", ".css"
}

# Extensions à exclure (fichiers binaires ou générés)
EXCLUDE_EXTENSIONS = {
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".pdf", ".zip", ".tar", ".gz",
    ".xcuserstate", ".xcuserdatad", ".xcworkspace"
}

def should_process_file(file_path):
    """Vérifie si un fichier doit être traité"""
    path = Path(file_path)
    
    # Vérifier l'extension
    if path.suffix.lower() in EXCLUDE_EXTENSIONS:
        return False
    
    # Si on a une liste d'extensions à inclure, vérifier
    if INCLUDE_EXTENSIONS and path.suffix.lower() not in INCLUDE_EXTENSIONS:
        # Mais on traite aussi les fichiers sans extension (comme certains scripts)
        if path.suffix:
            return False
    
    return True

def should_process_dir(dir_path):
    """Vérifie si un dossier doit être traité"""
    parts = Path(dir_path).parts
    return not any(part in EXCLUDE_DIRS for part in parts)

def replace_in_file(file_path):
    """Remplace les occurrences dans un fichier"""
    try:
        # Lire le fichier
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        
        original_content = content
        modified = False
        
        # Effectuer tous les remplacements
        for old_name, new_name in REPLACEMENTS.items():
            if old_name in content:
                content = content.replace(old_name, new_name)
                modified = True
        
        # Écrire seulement si modifié
        if modified:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            return True
        
        return False
    except Exception as e:
        # Ignorer les erreurs (fichiers binaires, permissions, etc.)
        return False

def main():
    """Fonction principale"""
    print("🔍 Recherche et remplacement des références...")
    print("=" * 60)
    
    project_root = Path(".")
    files_modified = 0
    files_checked = 0
    
    # Parcourir tous les fichiers
    for root, dirs, files in os.walk("."):
        # Filtrer les dossiers à exclure
        dirs[:] = [d for d in dirs if should_process_dir(os.path.join(root, d))]
        
        for file in files:
            file_path = os.path.join(root, file)
            
            # Vérifier si le fichier doit être traité
            if not should_process_file(file_path):
                continue
            
            files_checked += 1
            
            # Remplacer dans le fichier
            if replace_in_file(file_path):
                print(f"✔ Remplacé dans {file_path}")
                files_modified += 1
    
    print("=" * 60)
    print(f"✅ Remplacement terminé !")
    print(f"   - Fichiers vérifiés : {files_checked}")
    print(f"   - Fichiers modifiés : {files_modified}")
    print("")
    print("📋 Prochaines étapes :")
    print("   1. Ouvrir le projet dans Xcode")
    print("   2. Nettoyer : Product > Clean Build Folder (⇧⌘K)")
    print("   3. Compiler : Product > Build (⌘B)")
    print("   4. Vérifier qu'il n'y a pas d'erreurs")

if __name__ == "__main__":
    main()

