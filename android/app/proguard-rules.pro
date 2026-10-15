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

# Unity Ads SDK & Google Mediation Adapter
-keep public class com.google.ads.mediation.unity.** {
    public *;
    protected *;
}
-keep class com.google.ads.mediation.unity.** { *; }
-keep interface com.google.android.gms.ads.mediation.Adapter { *; }
-keep interface com.google.android.gms.ads.mediation.MediationAdapter { *; }
-keep class * extends com.google.android.gms.ads.mediation.Adapter { *; }
-keep class * implements com.google.android.gms.ads.mediation.Adapter { *; }
-keep class * implements com.google.android.gms.ads.mediation.MediationAdapter { *; }

-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.ads.**
-dontwarn com.unity3d.services.**

# Meta Audience Network & Mediation Adapter
-keep class com.google.ads.mediation.facebook.** { *; }
-keep class com.facebook.ads.** { *; }
-dontwarn com.facebook.ads.**

# WorkManager components required by Unity Ads in R8 full mode
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker { <init>(android.content.Context, androidx.work.WorkerParameters); }
-keep class * extends androidx.work.InputMerger { <init>(); }

# General
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.ump.**
-ignorewarnings
