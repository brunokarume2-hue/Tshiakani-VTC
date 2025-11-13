-- Script pour compiler et vérifier que l'erreur Info.plist est corrigée

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
        log "🔨 COMPILATION AVEC VÉRIFICATION Info.plist"
        log "==========================================="
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
        
        delay 10
        
        log ""
        log "==========================================="
        log "✅ Compilation lancée !"
        log ""
        log "📋 VÉRIFICATIONS:"
        log ""
        log "1. Regardez la barre d'état en haut de Xcode"
        log "   → Si 'Build Succeeded' : ✅ SUCCÈS !"
        log "   → Si 'Build Failed' : Vérifiez les erreurs"
        log ""
        log "2. Ouvrez le panneau d'erreurs (⌘5)"
        log "   → Il ne devrait PLUS y avoir d'erreur Info.plist"
        log ""
        log "3. Si l'erreur 'Multiple commands produce Info.plist'"
        log "   apparaît encore, c'est que la solution n'a pas"
        log "   fonctionné. Dans ce cas, envoyez-moi le message."
        log ""
        log "==========================================="
        
    end tell
end tell

