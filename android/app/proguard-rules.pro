# Flutter Engine rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the Local Notifications Plugin completely intact
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Prevent R8 from breaking on missing Core Library Desugaring classes
-dontwarn java.lang.invoke.**
-dontwarn j$.**