-- Script AppleScript pour compiler automatiquement dans Xcode

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
        log "🔨 FORÇAGE DE LA COMPILATION"
        log "============================"
        log ""
        
        -- Étape 1: Clean Build Folder
        log "Étape 1: Clean Build Folder..."
        try
            keystroke "k" using {shift down, command down}
            delay 3
            log "✅ Clean effectué"
        on error errMsg
            log "⚠️ Erreur Clean: " & errMsg
        end try
        
        delay 2
        
        -- Étape 2: Build
        log "Étape 2: Build..."
        try
            keystroke "b" using {command down}
            log "✅ Build lancé"
            log ""
            log "⏳ Attente de la compilation..."
            log "   (Cela peut prendre plusieurs minutes)"
        on error errMsg
            log "⚠️ Erreur Build: " & errMsg
        end try
        
        delay 5
        
        log ""
        log "============================"
        log "✅ Compilation lancée !"
        log ""
        log "📋 Vérifiez la barre d'état en haut de Xcode"
        log "   pour voir le résultat de la compilation"
        log ""
        
    end tell
end tell

