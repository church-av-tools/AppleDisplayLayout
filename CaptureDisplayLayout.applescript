on run
	try
		set configDir to (path to home folder as text) & ".config:display-layout:"
		set configFile to configDir & "display-layout.plist"
		
		set configDirPath to POSIX path of configDir
		set configFilePath to POSIX path of configFile
		
		do shell script "mkdir -p " & quoted form of configDirPath
		
		set displayplacerPath to findDisplayplacer()
		
		if displayplacerPath is "" then
			set installResult to offerDisplayplacerInstallation()
			if installResult is "install" then
				set installSuccess to installDisplayplacer()
				if installSuccess then
					set displayplacerPath to findDisplayplacer()
					if displayplacerPath is "" then
						display dialog "Installation completed, but displayplacer was not found. Please restart the script or check your PATH." buttons {"OK"} default button 1 with icon caution
						return
					end if
				else
					return
				end if
			else
				return
			end if
		end if
		
		set displayListOutput to do shell script quoted form of displayplacerPath & " list"
		
		set displayConfigs to {}
		set currentDisplay to {}
		set displayLines to paragraphs of displayListOutput
		
		repeat with aLine in displayLines
			set lineText to trimWhitespace(aLine)
			
			if lineText starts with "Persistent screen id:" then
				if (count of currentDisplay) > 0 then
					set end of displayConfigs to currentDisplay
				end if
				set currentDisplay to {}
				set screenId to extractValue(lineText, "Persistent screen id:")
				set end of currentDisplay to {key:"persistentScreenId", value:screenId}
			else if lineText starts with "Type:" then
				set displayType to extractValue(lineText, "Type:")
				set end of currentDisplay to {key:"type", value:displayType}
			else if lineText starts with "Resolution:" then
				set resolution to extractValue(lineText, "Resolution:")
				set end of currentDisplay to {key:"resolution", value:resolution}
			else if lineText starts with "Hertz:" then
				set hertz to extractValue(lineText, "Hertz:")
				set end of currentDisplay to {key:"hertz", value:hertz}
			else if lineText starts with "Color Depth:" then
				set colorDepth to extractValue(lineText, "Color Depth:")
				set end of currentDisplay to {key:"colorDepth", value:colorDepth}
			else if lineText starts with "Scaling:" then
				set scaling to extractValue(lineText, "Scaling:")
				set end of currentDisplay to {key:"scaling", value:scaling}
			else if lineText starts with "Origin:" then
				set originFull to extractValue(lineText, "Origin:")
				if originFull contains "- main display" then
					set origin to extractOriginCoordinates(originFull)
					set end of currentDisplay to {key:"origin", value:origin}
					set end of currentDisplay to {key:"isMain", value:"true"}
				else
					set origin to extractOriginCoordinates(originFull)
					set end of currentDisplay to {key:"origin", value:origin}
				end if
			else if lineText starts with "Rotation:" then
				set rotationFull to extractValue(lineText, "Rotation:")
				set rotationValue to extractNumericValue(rotationFull)
				set end of currentDisplay to {key:"rotation", value:rotationValue}
			else if lineText starts with "Color Profile:" then
				set colorProfile to extractValue(lineText, "Color Profile:")
				set end of currentDisplay to {key:"colorProfile", value:colorProfile}
			end if
		end repeat
		
		if (count of currentDisplay) > 0 then
			set end of displayConfigs to currentDisplay
		end if
		
		set plistData to createPlistFromDisplayConfigs(displayConfigs)
		
		do shell script "echo " & quoted form of plistData & " > " & quoted form of configFilePath
		
		set displayCount to count of displayConfigs
		display dialog "Display configuration captured successfully!" & return & return & "Saved " & displayCount & " display(s) to:" & return & configFilePath buttons {"OK"} default button 1 with icon note
		
	on error errorMessage
		display dialog "Error capturing display layout: " & errorMessage buttons {"OK"} default button 1 with icon stop
	end try
end run

on trimWhitespace(inputString)
	set AppleScript's text item delimiters to ""
	set trimmed to inputString
	repeat while trimmed starts with " " or trimmed starts with tab
		set trimmed to text 2 thru -1 of trimmed
	end repeat
	repeat while trimmed ends with " " or trimmed ends with tab
		set trimmed to text 1 thru -2 of trimmed
	end repeat
	return trimmed
end trimWhitespace

on extractValue(lineText, prefix)
	set prefixLength to length of prefix
	if length of lineText > prefixLength then
		set valueText to text (prefixLength + 1) thru -1 of lineText
		return trimWhitespace(valueText)
	end if
	return ""
end extractValue

on extractOriginCoordinates(originString)
	set openParenPos to offset of "(" in originString
	set closeParenPos to offset of ")" in originString
	if openParenPos > 0 and closeParenPos > openParenPos then
		return text openParenPos thru closeParenPos of originString
	end if
	return originString
end extractOriginCoordinates

on extractNumericValue(inputString)
	set trimmed to trimWhitespace(inputString)
	set numericPart to ""
	repeat with i from 1 to length of trimmed
		set currentChar to text i thru i of trimmed
		if currentChar is in "0123456789" then
			set numericPart to numericPart & currentChar
		else if numericPart is not "" then
			exit repeat
		end if
	end repeat
	return numericPart
end extractNumericValue

on createPlistFromDisplayConfigs(displayConfigs)
	set plistContent to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & return
	set plistContent to plistContent & "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" & return
	set plistContent to plistContent & "<plist version=\"1.0\">" & return
	set plistContent to plistContent & "<dict>" & return
	set plistContent to plistContent & "	<key>displays</key>" & return
	set plistContent to plistContent & "	<array>" & return
	
	repeat with displayConfig in displayConfigs
		set plistContent to plistContent & "		<dict>" & return
		
		repeat with configItem in displayConfig
			set itemKey to key of configItem
			set itemValue to value of configItem
			
			set plistContent to plistContent & "			<key>" & itemKey & "</key>" & return
			
			if itemKey is "isMain" then
				set plistContent to plistContent & "			<" & itemValue & "/>" & return
			else
				set plistContent to plistContent & "			<string>" & escapeXML(itemValue) & "</string>" & return
			end if
		end repeat
		
		set plistContent to plistContent & "		</dict>" & return
	end repeat
	
	set plistContent to plistContent & "	</array>" & return
	set plistContent to plistContent & "</dict>" & return
	set plistContent to plistContent & "</plist>" & return
	
	return plistContent
end createPlistFromDisplayConfigs

on escapeXML(inputString)
	set escaped to inputString
	set escaped to my replaceText(escaped, "&", "&amp;")
	set escaped to my replaceText(escaped, "<", "&lt;")
	set escaped to my replaceText(escaped, ">", "&gt;")
	set escaped to my replaceText(escaped, "\"", "&quot;")
	set escaped to my replaceText(escaped, "'", "&apos;")
	return escaped
end escapeXML

on replaceText(inputString, searchString, replaceString)
	set AppleScript's text item delimiters to searchString
	set textItems to text items of inputString
	set AppleScript's text item delimiters to replaceString
	set resultString to textItems as string
	set AppleScript's text item delimiters to ""
	return resultString
end replaceText

on findDisplayplacer()
	set possiblePaths to {"/usr/local/bin/displayplacer", "/opt/homebrew/bin/displayplacer", "/opt/homebrew/opt/displayplacer/bin/displayplacer"}
	
	repeat with testPath in possiblePaths
		try
			do shell script "test -f " & quoted form of testPath & " && echo exists"
			return testPath
		end try
	end repeat
	
	try
		set whichResult to do shell script "which displayplacer 2>/dev/null"
		if whichResult is not "" then
			return whichResult
		end if
	end try
	
	return ""
end findDisplayplacer

on offerDisplayplacerInstallation()
	set dialogResult to display dialog "displayplacer is not installed." & return & return & "Would you like to install it automatically using Homebrew?" buttons {"Install", "Cancel"} default button "Install" with icon question
	if button returned of dialogResult is "Install" then
		return "install"
	else
		return "cancel"
	end if
end offerDisplayplacerInstallation

on installDisplayplacer()
	try
		do shell script "brew install displayplacer" with administrator privileges
		
		display dialog "displayplacer installed successfully!" buttons {"OK"} default button 1 with icon note
		return true
	on error errorMessage
		display dialog "Failed to install displayplacer: " & errorMessage & return & return & "Please install manually using: brew install displayplacer" buttons {"OK"} default button 1 with icon stop
		return false
	end try
end installDisplayplacer

