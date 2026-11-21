#!/bin/bash
mkdir -p shots; APK=$(find z -name '*.apk' -path '*debug*' | head -1); echo "TEST_APK $APK"
adb install -r -t "$APK" 2>&1 | tail -3 || echo INSTALL_FAILED
PKG=$(/usr/local/lib/android/sdk/build-tools/$(ls /usr/local/lib/android/sdk/build-tools | tail -1)/aapt dump badging "$APK" | sed -n "s/package: name='\([^']*\)'.*/\1/p")
echo "PKG $PKG"; adb shell pm list packages | grep "$PKG"
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 2>&1 | tail -2
sleep 15; adb exec-out screencap -p > shots/launch1.png
adb shell dumpsys window | grep mCurrentFocus
echo "LAUNCH_FOCUS_OK=$(adb shell dumpsys window | grep mCurrentFocus | grep -c "$PKG")"
adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml shots/u1.xml >/dev/null 2>&1
echo "UI_TEXTS: $(grep -o 'text="[^"]\+"' shots/u1.xml | head -40 | tr '\n' ' ')"
echo MEMINFO_BEGIN; adb shell dumpsys meminfo "$PKG" | grep -E "TOTAL|Java Heap|Native Heap" | head -5; echo MEMINFO_END
echo FATAL_BEGIN; adb logcat -d | grep -B2 -A12 "FATAL EXCEPTION" | head -50; echo FATAL_END
adb logcat -d -s AndroidRuntime:E | head -20
