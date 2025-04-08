#!/bin/bash

# Replace these with your actual identifiers
ANDROID_PACKAGE="com.example.no_firebase_app"
IOS_BUNDLE_ID="com.example.noFirebaseApp"

echo "===> Uninstalling from Android emulators..."
ANDROID_DEVICES=$(adb devices | grep emulator | cut -f1)
for device in $ANDROID_DEVICES; do
  echo "Uninstalling $ANDROID_PACKAGE from $device"
  adb -s "$device" uninstall "$ANDROID_PACKAGE"
done

echo ""
echo "===> Uninstalling from iOS simulators..."
IOS_SIMULATORS=$(xcrun simctl list devices | grep -w Booted | sed -E 's/.*\(([-A-F0-9]+)\).*/\1/')
for udid in $IOS_SIMULATORS; do
  echo "Uninstalling $IOS_BUNDLE_ID from simulator $udid"
  xcrun simctl uninstall "$udid" "$IOS_BUNDLE_ID"
done

echo ""
echo "✅ Uninstall complete."

# Replace these with your actual identifiers
ANDROID_PACKAGE="com.example.test_notification_app"
IOS_BUNDLE_ID="com.example.testnotificationapp2"

echo "===> Uninstalling from Android emulators..."
ANDROID_DEVICES=$(adb devices | grep emulator | cut -f1)
for device in $ANDROID_DEVICES; do
  echo "Uninstalling $ANDROID_PACKAGE from $device"
  adb -s "$device" uninstall "$ANDROID_PACKAGE"
done

echo ""
echo "===> Uninstalling from iOS simulators..."
IOS_SIMULATORS=$(xcrun simctl list devices | grep -w Booted | sed -E 's/.*\(([-A-F0-9]+)\).*/\1/')
for udid in $IOS_SIMULATORS; do
  echo "Uninstalling $IOS_BUNDLE_ID from simulator $udid"
  xcrun simctl uninstall "$udid" "$IOS_BUNDLE_ID"
done

echo ""
echo "✅ Uninstall complete."
