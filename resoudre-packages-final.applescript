-- Script AppleScript pour forcer la résolution des packages et corriger les 2 erreurs
-- Erreurs: Missing package product 'GoogleMaps' et 'GooglePlaces'

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
        repeat 15 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        
        log "🔧 Résolution des 2 erreurs: GoogleMaps et GooglePlaces"
        log "=================================================="
        log ""
        
        -- Étape 1: Reset Package Caches
        log "Étape 1: Reset Package Caches..."
        try
            tell menu bar 1
                tell menu bar item "File"
                    tell menu "File"
                        tell menu item "Packages"
                            tell menu "Packages"
                                click menu item "Reset Package Caches"
                            end tell
                        end tell
                    end tell
                end tell
            end tell
            delay 5
            log "✅ Package caches réinitialisés"
        on error errMsg
            log "⚠️ Reset Package Caches: " & errMsg
        end try
        
        log ""
        
        -- Étape 2: Resolve Package Versions
        log "Étape 2: Resolve Package Versions..."
        try
            tell menu bar 1
                tell menu bar item "File"
                    tell menu "File"
                        tell menu item "Packages"
                            tell menu "Packages"
                                click menu item "Resolve Package Versions"
                            end tell
                        end tell
                    end tell
                end tell
            end tell
            log "✅ Résolution des packages démarrée"
            log ""
            log "⏳ IMPORTANT: La résolution peut prendre 2-5 minutes"
            log "   Surveillez la barre de progression en bas d'Xcode"
            log "   Attendez que tous les packages soient résolus avant de compiler"
        on error errMsg
            log "⚠️ Resolve Package Versions: " & errMsg
        end try
        
        delay 3
        
        log ""
        log "=================================================="
        log "✅ Actions automatiques terminées"
        log ""
        log "📋 Prochaines étapes:"
        log ""
        log "1. ⏳ Attendez que la résolution des packages se termine (2-5 min)"
        log "   → Surveillez la barre de progression en bas d'Xcode"
        log "   → Vérifiez dans Project Navigator > Package Dependencies"
        log ""
        log "2. ✅ Vérifiez que les packages sont résolus:"
        log "   → Project Navigator (⌘1) > Package Dependencies"
        log "   → Vous devriez voir:"
        log "     • ios-maps-sdk (Google Maps)"
        log "     • ios-places-sdk (Google Places)"
        log ""
        log "3. 🔨 Compilez le projet:"
        log "   → Product > Clean Build Folder (⇧⌘K)"
        log "   → Product > Build (⌘B)"
        log ""
        log "4. ✅ Les 2 erreurs devraient disparaître une fois les packages résolus"
        log ""
        log "=================================================="
        
    end tell
end tell

