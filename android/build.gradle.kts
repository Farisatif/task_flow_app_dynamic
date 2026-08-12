allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }
}

// بعض إضافات Flutter تُنشئ Android library مستقلة وتقرأ compileSdk الافتراضي
// من Flutter. نطبّق API 36 بعد تقييم كل وحدة كي يطابق متطلبات file_picker
// وflutter_plugin_android_lifecycle، بدل تعديل تطبيق :app فقط.
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application")) {
            extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
                compileSdk = 36
            }
        }
        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
