-- Script AppleScript pour forcer la résolution des packages en urgence
-- Corrige: Missing package product 'GoogleMaps'

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
        repeat 20 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        
        log "🔧 Résolution URGENTE des Packages GoogleMaps et GooglePlaces"
        log "============================================================"
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
            delay 8
            log "✅ Package caches réinitialisés"
        on error errMsg
            log "⚠️ Reset Package Caches: " & errMsg
            log "   → Essayez manuellement: File > Packages > Reset Package Caches"
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
            log "⏳ CRITIQUE: La résolution peut prendre 2-5 minutes"
            log "   → Surveillez la barre de progression en bas d'Xcode"
            log "   → Ne fermez PAS Xcode pendant la résolution"
            log "   → Attendez que tous les packages soient résolus"
        on error errMsg
            log "⚠️ Resolve Package Versions: " & errMsg
            log "   → Essayez manuellement: File > Packages > Resolve Package Versions"
        end try
        
        delay 3
        
        log ""
        log "============================================================"
        log "✅ Actions automatiques terminées"
        log ""
        log "📋 Vérification (après 2-5 minutes):"
        log ""
        log "1. Project Navigator (⌘1) > Package Dependencies"
        log "   → Vérifiez que vous voyez:"
        log "     • ios-maps-sdk (Google Maps)"
        log "     • ios-places-sdk (Google Places)"
        log ""
        log "2. Si les packages sont résolus:"
        log "   → Product > Clean Build Folder (⇧⌘K)"
        log "   → Product > Build (⌘B)"
        log ""
        log "3. L'erreur 'Missing package product GoogleMaps' devrait disparaître"
        log ""
        log "============================================================"
        
    end tell
end tell

