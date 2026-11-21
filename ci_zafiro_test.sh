#!/bin/bash
mkdir -p shots; APK=$(find z -name '*.apk' -path '*debug*' | head -1); echo "TEST_APK $APK"
BT=/usr/local/lib/android/sdk/build-tools/$(ls /usr/local/lib/android/sdk/build-tools | tail -1)
adb install -r -t "$APK" 2>&1 | tail -2
PKG=$($BT/aapt dump badging "$APK" | sed -n "s/package: name='\([^']*\)'.*/\1/p")
echo "LAUNCHABLE: $($BT/aapt dump badging "$APK" | grep -E 'launchable-activity' | sed "s/.*name='\([^']*\)'.*/\1/" | tr '\n' ' ')"
ACT=$($BT/aapt dump badging "$APK" | grep launchable-activity | sed "s/.*name='\([^']*\)'.*/\1/" | grep -vi leakcanary | head -1)
echo "MAIN_ACT $ACT"
# grant overlay + notifications so the app is not blocked (no accessibility, no real keys)
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>&1 | head -1
adb logcat -c
adb shell am start -n "$PKG/$ACT" 2>&1 | tail -2
sleep 20; adb exec-out screencap -p > shots/main1.png
echo "FOCUS: $(adb shell dumpsys window | grep mCurrentFocus)"
dump(){ adb shell uiautomator dump /sdcard/u.xml >/dev/null 2>&1; adb pull /sdcard/u.xml shots/$1.xml >/dev/null 2>&1; echo "UI_$1: $(grep -o 'text="[^"]\+"' shots/$1.xml | head -50 | tr '\n' ' ')"; echo "DESC_$1: $(grep -o 'content-desc="[^"]\+"' shots/$1.xml | head -30 | tr '\n' ' ')"; }
dump main1
echo MEMINFO_MAIN_BEGIN; adb shell dumpsys meminfo "$PKG" | grep -E "TOTAL PSS|TOTAL RSS|Java Heap:|Native Heap:" | head -4; echo MEMINFO_MAIN_END
adb shell input swipe 540 1500 540 600 300; sleep 2; adb exec-out screencap -p > shots/main2.png; dump main2
echo FATAL_BEGIN; adb logcat -d | grep -A8 "FATAL EXCEPTION" | head -60; echo FATAL_END
echo PROCS: $(adb shell ps -A | grep "$PKG" | awk '{print $NF" rss="$6}' | tr '\n' ' ')
