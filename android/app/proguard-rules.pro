# Flutter's deferred-components loader references Play Core classes that
# aren't in this project (no dynamic feature modules) — R8 fails on missing
# classes without this. Standard rule from https://docs.flutter.dev/deployment/android#r8
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager
-dontwarn com.google.android.play.core.**
