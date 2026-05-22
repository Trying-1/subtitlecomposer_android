import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    val isAabTask = project.gradle.startParameter.taskNames.any { task ->
        task.contains("bundle", ignoreCase = true) || task.contains("AppBundle", ignoreCase = true)
    }
    val storagePerm = if (isAabTask) {
        "android.permission.READ_EXTERNAL_STORAGE"
    } else {
        "android.permission.MANAGE_EXTERNAL_STORAGE"
    }

    namespace = "com.typography"
    compileSdk = 36
    ndkVersion = "27.3.13750724"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.typography"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["storagePermission"] = storagePerm

        ndk {
            abiFilters.add("arm64-v8a")
        }

        externalNativeBuild {
            cmake {
                arguments("-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384", "-DCMAKE_EXE_LINKER_FLAGS=-Wl,-z,max-page-size=16384")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    applicationVariants.all {
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            val appName = "TypoEdit"
            val version = versionName
            val build = versionCode
            output.outputFileName = "${appName}_v${version}(${build}).apk"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.22.0")
}
