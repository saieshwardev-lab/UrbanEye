// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Kotlin DSL uses `implementation(...)` style
        classpath("com.google.gms:google-services:4.4.2")                // Google Services (Sign-In, FCM)
        classpath("com.google.firebase:perf-plugin:1.4.2")               // Firebase Performance
        classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9") // Crashlytics
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Keep Flutter’s build directory override
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(name)
    layout.buildDirectory.value(newSubprojectBuildDir)
}

// ✅ Ensure app module is evaluated first
subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
