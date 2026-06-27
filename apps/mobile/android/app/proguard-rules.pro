# ProGuard/R8 Rules for Glicoo Mobile

# Keep Flutter Workmanager Plugin classes from being stripped
-keep class dev.fluttercommunity.workmanager.** { *; }

# Keep Android Jetpack WorkManager classes and implementations
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>(...);
}
-keep class androidx.work.impl.background.systemalarm.SystemAlarmService { *; }
-keep class androidx.work.impl.background.systemjob.SystemJobService { *; }
-keep class androidx.work.impl.foreground.SystemForegroundService { *; }

# Keep Android Room database classes (used by WorkManager)
-keep class androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.room.**
-dontwarn androidx.work.**

# Keep Flutter Local Notifications Plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
