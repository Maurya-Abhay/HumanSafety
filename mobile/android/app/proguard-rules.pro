# Proguard Rules for HumanSafety App
# Optimizes code shrinking and obfuscation while keeping essential functionality

#############################################
# KEEP Flutter Framework
#############################################
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep interface io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

#############################################
# KEEP App Classes (essential features)
#############################################
-keep class com.humansafety.mobile.** { *; }
-keep interface com.humansafety.mobile.** { *; }

#############################################
# KEEP Firebase/Google Services (if needed later)
#############################################
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }

#############################################
# KEEP Provider (State Management)
#############################################
-keep class provider.** { *; }
-keep interface provider.** { *; }

#############################################
# KEEP Plugin Classes
#############################################
-keep class ** extends io.flutter.embedding.engine.FlutterPlugin
-keep class ** implements io.flutter.embedding.engine.FlutterPlugin
-keep class ** extends android.app.Service

#############################################
# Remove Logging (saves space)
#############################################
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

#############################################
# Optimization settings
#############################################
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose

# Remove unused resources
-dontshrink
