# Flutter Play Core / Deferred Components
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# photo_manager
-keep class com.fluttercandies.photo_manager.** { *; }

# media_kit
-keep class com.alexmercerind.media_kit_video.** { *; }
-keep class com.alexmercerind.media_kit_libs_android_video.** { *; }

# Hive
-keep class hive.** { *; }
-keepclassmembers class * extends hive.TypeAdapter { *; }
