-- Script pour résoudre automatiquement les packages dans Xcode

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
        log "📦 RÉSOLUTION AUTOMATIQUE DES PACKAGES"
        log "======================================"
        log ""
        
        -- Étape 1: Reset Package Caches
        log "Étape 1: Reset Package Caches..."
        try
            -- File > Packages > Reset Package Caches
            keystroke "f" using {command down}
            delay 0.5
            
            -- Naviguer vers Packages
            key code 48 -- Tab
            delay 0.5
            key code 48 -- Tab
            delay 0.5
            key code 36 -- Return
            delay 1
            
            -- Reset Package Caches
            key code 36 -- Return
            delay 2
            
            log "✅ Reset Package Caches effectué"
        on error errMsg
            log "⚠️ Erreur Reset: " & errMsg
        end try
        
        delay 3
        
        -- Étape 2: Resolve Package Versions
        log "Étape 2: Resolve Package Versions..."
        try
            -- File > Packages > Resolve Package Versions
            keystroke "f" using {command down}
            delay 0.5
            
            -- Naviguer vers Packages
            key code 48 -- Tab
            delay 0.5
            key code 48 -- Tab
            delay 0.5
            key code 36 -- Return
            delay 1
            
            -- Resolve Package Versions (première option)
            key code 36 -- Return
            delay 1
            
            log "✅ Resolve Package Versions lancé"
            log ""
            log "⏳ Attente de la résolution des packages..."
            log "   (Cela peut prendre 1-2 minutes)"
        on error errMsg
            log "⚠️ Erreur Resolve: " & errMsg
        end try
        
        delay 10
        
        -- Étape 3: Clean Build Folder
        log ""
        log "Étape 3: Clean Build Folder..."
        try
            keystroke "k" using {shift down, command down}
            delay 3
            log "✅ Clean effectué"
        on error errMsg
            log "⚠️ Erreur Clean: " & errMsg
        end try
        
        delay 2
        
        -- Étape 4: Build
        log "Étape 4: Build..."
        try
            keystroke "b" using {command down}
            log "✅ Build lancé"
        on error errMsg
            log "⚠️ Erreur Build: " & errMsg
        end try
        
        delay 5
        
        log ""
        log "======================================"
        log "✅ Processus terminé !"
        log ""
        log "📋 VÉRIFICATIONS:"
        log ""
        log "1. Regardez la barre d'état en haut de Xcode"
        log "   → Si 'Resolving packages...' : Attendez la fin"
        log "   → Si 'Build Succeeded' : ✅ SUCCÈS !"
        log "   → Si 'Build Failed' : Vérifiez les erreurs"
        log ""
        log "2. Ouvrez le panneau d'erreurs (⌘5)"
        log "   → Les erreurs 'Missing package product' devraient"
        log "     disparaître après la résolution"
        log ""
        log "3. Si les erreurs persistent:"
        log "   → Attendez encore 1-2 minutes pour la résolution"
        log "   → Puis recompilez (⌘B)"
        log ""
        log "======================================"
        
    end tell
end tell

