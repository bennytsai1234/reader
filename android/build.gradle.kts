allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            // 自動修復缺失的 namespace
            if (namespace == null) {
                namespace = "io.legado.reader.${project.name.replace("-", ".")}"
            }
            
            // 強制注入 Android SDK 核心庫 Classpath，修復 "package android.content does not exist" 等錯誤
            tasks.withType<JavaCompile>().configureEach {
                val sdkPath = android.sdkDirectory.absolutePath
                val compileSdkVer = android.compileSdkVersion ?: "android-35"
                val androidJar = file("$sdkPath/platforms/$compileSdkVer/android.jar")
                if (androidJar.exists()) {
                    options.bootstrapClasspath = files(androidJar)
                }
            }

            // 專門修復 isar_flutter_libs 3.1.0+1 在 AGP 8.0+ 下的 Manifest 衝突
            if (project.name == "isar_flutter_libs") {
                namespace = "dev.isar.isar_flutter_libs"
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=\"dev.isar.isar_flutter_libs\"")) {
                        println("Fixing isar_flutter_libs manifest: removing package attribute")
                        manifestFile.writeText(content.replace("package=\"dev.isar.isar_flutter_libs\"", ""))
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 強制所有 Android 模組 (包括 plugins) 使用 JVM 17
allprojects {
    configurations.all {
        resolutionStrategy {
            // ...
        }
    }
}

gradle.projectsEvaluated {
    allprojects {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
