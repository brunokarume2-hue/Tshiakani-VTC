-- Script pour réinstaller les packages automatiquement

tell application "Xcode"
    activate
    delay 2
    
    set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
    
    try
        open projectPath
        delay 5
        log "✅ Projet ouvert"
    on error errMsg
        log "⚠️ Erreur: " & errMsg
    end try
end tell

tell application "System Events"
    tell process "Xcode"
        -- Attendre que Xcode soit prêt
        repeat 30 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        
        log ""
        log "📦 RÉINSTALLATION DES PACKAGES"
        log "=============================="
        log ""
        
        -- Étape 1: Reset Package Caches
        log "Étape 1: Reset Package Caches..."
        try
            keystroke "f" using {command down}
            delay 0.5
            key code 48 -- Tab
            delay 0.5
            key code 48 -- Tab
            delay 0.5
            key code 36 -- Return
            delay 1
            key code 36 -- Return
            delay 2
            log "✅ Reset Package Caches effectué"
        on error errMsg
            log "⚠️ Erreur Reset: " & errMsg
        end try
        
        delay 5
        
        log ""
        log "=============================="
        log "✅ Reset effectué"
        log ""
        log "📋 PROCHAINES ÉTAPES MANUELLES:"
        log ""
        log "1. File > Packages > Resolve Package Versions"
        log "   → Attendez 2-3 minutes"
        log ""
        log "2. Si ios-maps-sdk échoue encore:"
        log "   → File > Packages > Remove Package"
        log "   → Sélectionnez ios-maps-sdk"
        log "   → File > Add Package Dependencies..."
        log "   → URL: https://github.com/googlemaps/ios-maps-sdk"
        log "   → Version: Up to Next Major Version (10.4.0)"
        log ""
        log "3. Product > Clean Build Folder (⇧⌘K)"
        log ""
        log "4. Product > Build (⌘B)"
        log ""
        
    end tell
end tell

