# R8/ProGuard 규칙 (release minify). 리플렉션·네이티브 쓰는 곳 보호.
# 대부분 플러그인은 자체 consumer 규칙이 있어 자동 유지되지만, 방어적으로 keep.

# Flutter 엔진
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Firebase / Google Play Services (analytics, messaging)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# 공통: 애노테이션/시그니처/네이티브 메서드/enum 유지 (리플렉션 안전)
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclasseswithmembernames class * { native <methods>; }
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 직렬화(Parcelable/Serializable) 안전
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
