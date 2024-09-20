#!/usr/bin/env bash
#
# Uninstall the application and remove the settings and permissions
#
# Usage: ./uninstall-app.sh

# Remove the settings and permissions (should happen before removing the app)
tccutil reset All com.github.CopilotForXcode
tccutil reset All com.github.CopilotForXcode.ExtensionService

# Remove dev versions as well
tccutil reset All dev.com.github.CopilotForXcode
tccutil reset All dev.com.github.CopilotForXcode.ExtensionService

# Remove launch agent
launchctl remove com.github.CopilotForXcode.CommunicationBridge
launchctl remove dev.com.github.CopilotForXcode.CommunicationBridge

# Remove app
rm -rf /Applications/Copilot\ for\ Xcode.app
rm -rf /Applications/GitHub\ Copilot\ for\ Xcode.app

# Remove user preferences
rm -f ~/Library/Preferences/com.github.CopilotForXcode.plist
rm -f ~/Library/Preferences/com.github.CopilotForXcode.ExtensionService.plist
rm -f ~/Library/Preferences/dev.com.github.CopilotForXcode.plist
rm -f ~/Library/Preferences/dev.com.github.CopilotForXcode.ExtensionService.plist

echo 'Finished'

