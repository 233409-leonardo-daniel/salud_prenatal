# =====================================================================
# Reglas de R8/ProGuard para Salud Prenatal
# Objetivo: ofuscar (renombrar clases/métodos) y eliminar código no usado
# SIN romper Flutter ni las librerías de terceros del proyecto.
# =====================================================================

# ---- Flutter (motor y embedding) ----
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Firebase / Google Play Services (firebase_core, firebase_messaging) ----
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ---- flutter_local_notifications (usa Gson por reflexión) ----
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ---- Modelos serializados por Gson (evita que R8 renombre sus campos) ----
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ---- Metadatos útiles para stack traces y reflexión ----
-keepattributes InnerClasses, EnclosingMethod, Exceptions, SourceFile, LineNumberTable

# ---- Enumeraciones (valueOf/values usados por reflexión) ----
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ---- Actividad principal de la app ----
-keep class com.vego.salud_prenatal.** { *; }
