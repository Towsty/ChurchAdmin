#!/bin/bash

# Clean up previous builds
flutter clean
flutter pub get

# Remove existing pods
cd macos
rm -rf Pods Podfile.lock

# Install pods
pod install

# Find the BoringSSL-GRPC target in the Pods project
PODS_PROJECT="Pods/Pods.xcodeproj/project.pbxproj"
if [ -f "$PODS_PROJECT" ]; then
    # Remove the problematic -G flag from the BoringSSL-GRPC target
    sed -i '' 's/-G //g' "$PODS_PROJECT"
    echo "Removed -G flag from BoringSSL-GRPC configuration"
fi

cd ..

# Build the project
flutter build macos --release 