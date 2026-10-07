# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# audio_service
-keep class com.ryanheise.audioservice.** { *; }
-keep interface com.ryanheise.audioservice.** { *; }

# just_audio
-keep class com.ryanheise.just_audio.** { *; }
-keep interface com.ryanheise.just_audio.** { *; }

# ExoPlayer / Media
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**