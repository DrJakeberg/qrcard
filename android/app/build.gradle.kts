import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signierung fuer Release-Builds.
//
// Die Zugangsdaten kommen entweder aus android/key.properties (lokal) oder aus
// Umgebungsvariablen (Codemagic). Beides fehlt? Dann wird mit dem
// Debug-Schluessel signiert - das reicht zum Ausprobieren, wird vom Play Store
// aber abgelehnt.
//
// Weder key.properties noch die Keystore-Datei gehoeren ins Repository;
// android/.gitignore schliesst beide aus.
val keystoreProperties = Properties()
rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use {
    keystoreProperties.load(it)
}

fun signingValue(fileKey: String, envKey: String): String? =
    keystoreProperties.getProperty(fileKey) ?: System.getenv(envKey)

val releaseStoreFile = signingValue("storeFile", "CM_KEYSTORE_PATH")
val releaseStorePassword = signingValue("storePassword", "CM_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "CM_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "CM_KEY_PASSWORD")

val hasReleaseSigning = releaseStoreFile != null &&
    releaseStorePassword != null &&
    releaseKeyAlias != null &&
    releaseKeyPassword != null

android {
    namespace = "de.cyb8.qrcode"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.cyb8.qrcode"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Ohne eigenen Schluessel laesst sich die App zwar bauen und
                // seitlich installieren, aber nicht in den Play Store laden.
                logger.lifecycle(
                    "Kein Release-Keystore gefunden - es wird mit dem " +
                        "Debug-Schluessel signiert.",
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
