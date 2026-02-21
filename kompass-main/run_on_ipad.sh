#!/bin/bash
set -e

# Device ID for the connected iPad
DEVICE_ID="00008112-001C259101F0C01E"

echo "Building app for physical iPad..."
# Navigate to the package directory
cd "/Users/student/Desktop/Aadi Shah/kompass.swiftpm"

# Build for generic iOS device (physical)
# Note: Physical devices usually require signing, but we'll try to bypass if the environment allows
xcodebuild -scheme kompass -destination "platform=iOS,id=$DEVICE_ID" -derivedDataPath ".build_ipad" build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO ENTITLEMENTS_REQUIRED=NO

echo "Installing on iPad..."
APP_PATH=$(find .build_ipad -name "kompass.app" | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "Error: App bundle not found!"
    exit 1
fi

echo "Found app at: $APP_PATH"

# Use devicectl to install and launch
echo "Installing to device $DEVICE_ID..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "Launching on device $DEVICE_ID..."
xcrun devicectl device process launch --device "$DEVICE_ID" "com.aadishah.kompass"
