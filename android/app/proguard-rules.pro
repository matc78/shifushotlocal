# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore models (reflection)
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName *;
}

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Play Core (deferred components, used by Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Keep generic signal classes used by reflection in plugins
-keepclassmembers,allowobfuscation class * {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <methods>;
}

# Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# JSR 305 annotations are for embedding nullability info
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**

# OkHttp (used by Firebase / http)
-dontwarn okhttp3.**
-dontwarn okio.**
