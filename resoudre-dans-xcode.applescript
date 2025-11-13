tell application "Xcode"
	activate
	delay 1
	
	-- Ouvrir le projet
	set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
	try
		open projectPath
		delay 3
	end try
	
	-- Instructions
	display dialog "Le projet est ouvert dans Xcode." & return & return & "Le script va maintenant essayer de résoudre les packages automatiquement." & return & return & "Si cela ne fonctionne pas, suivez ces étapes manuellement:" & return & return & "1. File > Packages > Reset Package Caches" & return & "2. File > Packages > Resolve Package Versions" buttons {"Continuer"} default button "Continuer"
	
	-- Essayer d'utiliser les raccourcis clavier
	tell application "System Events"
		tell process "Xcode"
			-- Essayer File > Packages > Resolve Package Versions
			keystroke "f" using {command down, shift down}
			delay 1
		end tell
	end tell
end tell
