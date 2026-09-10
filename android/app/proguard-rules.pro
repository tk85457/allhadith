# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Isar rules
-keep class io.isar.** { *; }
-keep class * implements io.isar.IsarObject { *; }
-keep interface io.isar.IsarObject { *; }
-keep class _*IsarSchema { *; }

# Sqflite rules
-keep class com.tekartik.sqflite.** { *; }

# Google Play Services Ads & UMP rules
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }

# General
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.ump.**
-ignorewarnings
