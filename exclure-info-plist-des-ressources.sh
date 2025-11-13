#!/bin/bash

# Script pour exclure Info.plist des ressources dans Xcode
# Ce script doit être exécuté depuis Xcode comme script de build

# Le problème : Avec PBXFileSystemSynchronizedRootGroup, Info.plist peut être
# automatiquement inclus dans les ressources, ce qui cause l'erreur
# "Multiple commands produce Info.plist"

# Solution : Ce script supprime Info.plist du bundle après la phase de ressources
# Mais en fait, la meilleure solution est de configurer le projet correctement

echo "⚠️ Ce script ne devrait pas être nécessaire si le projet est correctement configuré"
echo "Vérifiez que Info.plist n'est pas dans Copy Bundle Resources dans Xcode"

