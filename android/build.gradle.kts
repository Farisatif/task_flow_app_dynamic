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
// من Flutter. finalizeDsl يعمل بعد قراءة Android DSL لكل إضافة وقبل إنشاء
// variants، لذلك يفرض API 36 دون تسجيل hook متأخر على مشروع مكتمل.
subprojects {
    pluginManager.withPlugin("com.android.application") {
        extensions.configure<com.android.build.api.variant.ApplicationAndroidComponentsExtension> {
            finalizeDsl { extension ->
                extension.compileSdk = 36
            }
        }
    }
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl { extension ->
                extension.compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
