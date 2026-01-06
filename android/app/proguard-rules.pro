# ===================================================
# ProGuard Rules for Valiot Dashboard (Flutter App)
# ===================================================

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions

# Keep generic signature (for reflection)
-keepattributes Signature

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Prevent obfuscation of model classes (if using JSON serialization)
# Uncomment and adjust if you have model classes
# -keep class com.example.valiotdashboard.models.** { *; }

# Keep Parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Gson/JSON related (if using)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp / Retrofit (if using)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# MQTT Client (if using)
-keep class org.eclipse.paho.** { *; }
-dontwarn org.eclipse.paho.**

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep crash reporting
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ===================================================
# Add plugin-specific rules below if needed
# ===================================================
