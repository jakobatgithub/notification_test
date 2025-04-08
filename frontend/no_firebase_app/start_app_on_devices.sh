#!/bin/bash

# ✅ Number of emulators to use (default: 3)
NUM_EMULATORS=${1:-3}
echo "🔢 Targeting $NUM_EMULATORS running emulator(s)..."

# ✅ Get list of already running emulator device IDs
emulator_ids=($(adb devices | grep emulator | grep "device$" | cut -f1 | head -n $NUM_EMULATORS))

# ✅ Check we have enough emulators
if [ "${#emulator_ids[@]}" -lt "$NUM_EMULATORS" ]; then
  echo "❌ Only found ${#emulator_ids[@]} running emulator(s), but need $NUM_EMULATORS."
  echo "💡 Please start more emulators using Android Studio or the command line."
  exit 1
fi

echo "✅ Using the following running emulator(s): ${emulator_ids[*]}"

# ✅ Build Flutter app once
echo "🏗️ Building Flutter app..."
flutter build apk --debug || exit 1

# ✅ Install and launch app on each running emulator
for emulator_id in "${emulator_ids[@]}"; do
  echo "📲 Installing on $emulator_id..."
  adb -s "$emulator_id" install -r build/app/outputs/flutter-apk/app-debug.apk
  echo "🚀 Launching app on $emulator_id..."
  adb -s "$emulator_id" shell monkey -p "com.example.no_firebase_app" -c android.intent.category.LAUNCHER 1
done