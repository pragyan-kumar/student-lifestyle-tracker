# ProGuard & R8 configuration for EcoLife release APK

# Flutter Engine & Framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Secure Storage & AndroidX Security
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# Shared Preferences & Hive
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Serialization / Reflection models
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
