#!/bin/bash

NUM_ANDROID=${1:-3}
NUM_IOS=${2:-0}

echo "📱 Targeting $NUM_ANDROID Android emulator(s) and $NUM_IOS iOS simulator(s)"

### --- ANDROID SECTION ---
if [ "$NUM_ANDROID" -gt 0 ]; then
  echo "🔍 Checking Android emulators..."

  android_ids=($(adb devices | grep emulator | grep "device$" | cut -f1 | head -n $NUM_ANDROID))

  if [ "${#android_ids[@]}" -lt "$NUM_ANDROID" ]; then
    echo "❌ Only found ${#android_ids[@]} running Android emulator(s), need $NUM_ANDROID."
    exit 1
  fi

  echo "✅ Using Android emulator(s): ${android_ids[*]}"

  # Build Flutter app for Android
  echo "🏗️ Building Android APK..."
  flutter build apk --debug || exit 1

  APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
  if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at: $APK_PATH"
    exit 1
  fi

  # Install and launch on Android emulators
  for id in "${android_ids[@]}"; do
    echo "📲 Installing on $id..."
    adb -s "$id" install -r "$APK_PATH"

    echo "🚀 Launching app on $id..."
    adb -s "$id" shell monkey -p "com.example.test_notification_app" -c android.intent.category.LAUNCHER 1
  done
fi

## --- iOS SECTION ---
if [ "$NUM_IOS" -gt 0 ]; then
  echo "🔍 Checking iOS simulators..."

  ios_ids=($(xcrun simctl list devices | grep -E "Booted" | grep -oE '[A-F0-9\-]{36}' | head -n $NUM_IOS))

  if [ "${#ios_ids[@]}" -lt "$NUM_IOS" ]; then
    echo "❌ Only found ${#ios_ids[@]} booted iOS simulator(s), need $NUM_IOS."
    echo "💡 Start more in Simulator.app or Xcode."
    exit 1
  fi

  echo "✅ Using iOS simulator(s): ${ios_ids[*]}"

  # Build Flutter app for iOS simulator
  echo "🏗️ Building iOS app for simulator..."
  flutter build ios --simulator --debug || exit 1

  APP_PATH="build/ios/iphonesimulator/Runner.app"
  if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    exit 1
  fi

  # Install and launch on iOS simulators
  for sim_id in "${ios_ids[@]}"; do
    echo "📲 Installing on iOS simulator $sim_id..."
    xcrun simctl install "$sim_id" "$APP_PATH"

    echo "🚀 Launching app on iOS simulator $sim_id..."
    xcrun simctl launch "$sim_id" "com.example.testnotificationapp2"
  done
fi

echo "🎉 All done!"
