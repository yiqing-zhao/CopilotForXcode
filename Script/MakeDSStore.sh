#!/usr/bin/env bash

set -e

# Ensure we're in the root of the repo
cd "$(dirname "$0")/.."

# Must have python3 installed
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found. Install phyton3 and try again."
    exit 1
fi

# We need a volume with the background image in order to create the correct alias for it
mkdir -p build/image/.background
cp PackageAssets/background.png build/image/.background
hdiutil create -volname "GitHub Copilot for Xcode" -srcfolder build/image -format UDRW build/GitHubCopilotforXcode.dmg
hdiutil attach -readwrite build/GitHubCopilotforXcode.dmg


# Create a python virtual environment
mkdir -p build/venv
python3 -m venv build/venv

# Install ds-store
./build/venv/bin/pip install ds-store mac-alias==2.2.0 ds-store==1.3.0
./build/venv/bin/python Script/MakeDSStore.py

# Run it
./build/venv/bin/python Script/MakeDSStore.py

# Save the created .DS_Store file
cp '/Volumes/GitHub Copilot for Xcode/DSStore.template' PackageAssets/DSStore.template

# Clean up
hdiutil detach '/Volumes/GitHub Copilot for Xcode'
rm -rf build/GitHubCopilotforXcode.dmg
rm -rf build/image
rm -rf build/venv
