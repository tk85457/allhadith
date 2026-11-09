# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

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
# --- Gson / flutter_local_notifications (FIX: Gson TypeToken RuntimeException) ---
# flutter_local_notifications persists and reloads scheduled notifications with
# Gson using anonymous `new TypeToken<...>() {}` subclasses. R8 full mode strips
# the generic `Signature` attribute, so TypeToken.getSuperclassTypeParameter()
# throws "TypeToken must be created with a type argument" the moment the
# alarm / boot receiver fires. These rules are the official Gson R8 rules.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.stream.** { *; }
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Notification model classes are (de)serialised by Gson through reflection:
# their field names must survive shrinking/obfuscation.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.** { *; }

-ignorewarnings

