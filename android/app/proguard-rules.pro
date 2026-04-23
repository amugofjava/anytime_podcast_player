# MediaPipe (used by flutter_gemma) references generated protobuf classes that
# are not always present on the classpath; keep R8 from failing the build.
-dontwarn com.google.mediapipe.proto.**
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }

# flutter_gemma / TensorFlow Lite support classes occasionally get stripped.
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**
