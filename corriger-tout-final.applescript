-- Script AppleScript final pour corriger toutes les erreurs restantes
-- Retire Info.plist des ressources, vérifie les frameworks, et compile

tell application "Xcode"
    activate
    delay 3
    
    -- Ouvrir le projet si pas déjà ouvert
    set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
    try
        open projectPath
        delay 5
    end try
end tell

tell application "System Events"
    tell process "Xcode"
        -- Attendre que Xcode soit chargé
        repeat 10 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        
        log "🔍 Étape 1: Vérification des packages..."
        
        -- Vérifier si les packages sont résolus
        try
            -- Ouvrir le Project Navigator
            keystroke "1" using {command down}
            delay 1
            
            -- Chercher Package Dependencies
            keystroke "f" using {command down}
            delay 1
            keystroke "Package Dependencies"
            delay 1
            keystroke "g" using {command down}
            delay 2
            
            log "✅ Project Navigator ouvert"
        on error errMsg
            log "⚠️ Navigation: " & errMsg
        end try
        
        log ""
        log "🔍 Étape 2: Retirer Info.plist de Copy Bundle Resources..."
        log "   (Cette action nécessite une interaction manuelle)"
        log ""
        log "   Instructions:"
        log "   1. Sélectionnez le target 'Tshiakani VTC' (icône bleue)"
        log "   2. Allez dans l'onglet 'Build Phases'"
        log "   3. Développez 'Copy Bundle Resources'"
        log "   4. Si Info.plist est présent, sélectionnez-le et supprimez-le (bouton -)"
        log ""
        
        log "🔍 Étape 3: Vérifier les frameworks..."
        log "   (Cette action nécessite une interaction manuelle)"
        log ""
        log "   Instructions:"
        log "   1. Target 'Tshiakani VTC' > General"
        log "   2. Section 'Frameworks, Libraries, and Embedded Content'"
        log "   3. Vérifiez que GoogleMaps et GooglePlaces sont présents"
        log "   4. Si absents, ajoutez-les via le bouton '+'"
        log ""
        
        log "🔍 Étape 4: Nettoyer et compiler..."
        
        -- Nettoyer
        try
            tell menu bar 1
                tell menu bar item "Product"
                    tell menu "Product"
                        click menu item "Clean Build Folder"
                    end tell
                end tell
            end tell
            delay 2
            log "✅ Clean Build Folder effectué"
        on error errMsg
            log "⚠️ Clean Build Folder: " & errMsg
        end try
        
        -- Compiler
        try
            tell menu bar 1
                tell menu bar item "Product"
                    tell menu "Product"
                        click menu item "Build"
                    end tell
                end tell
            end tell
            log "✅ Build démarré"
            log "⏳ Surveillez la barre de progression et les erreurs dans Xcode"
        on error errMsg
            log "⚠️ Build: " & errMsg
        end try
        
        delay 2
        
    end tell
end tell

log ""
log "=========================================="
log "✅ Automatisation terminée"
log "=========================================="
log ""
log "📋 Actions effectuées automatiquement:"
log "   ✅ Clean Build Folder"
log "   ✅ Build démarré"
log ""
log "📋 Actions à faire manuellement:"
log "   1. Retirer Info.plist de Copy Bundle Resources (si présent)"
log "   2. Vérifier que les frameworks GoogleMaps et GooglePlaces sont liés"
log "   3. Attendre la fin de la compilation et vérifier les erreurs"
log ""
log "💡 Si des erreurs persistent:"
log "   - Vérifiez que les packages sont bien résolus (Project Navigator > Package Dependencies)"
log "   - Vérifiez que les frameworks sont bien liés (General > Frameworks)"
log "   - Relancez: Product > Clean Build Folder puis Product > Build"
log ""

