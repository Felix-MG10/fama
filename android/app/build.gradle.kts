import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val keystorePropertiesExist = keystorePropertiesFile.exists()
if (keystorePropertiesExist) {
    FileInputStream(keystorePropertiesFile).use { input ->
        keystoreProperties.load(input)
    }
}

android {
    namespace = "com.dakarapps.fama"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dakarapps.fama"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesExist) {
                val keyAlias = keystoreProperties["keyAlias"] as String?
                val keyPassword = keystoreProperties["keyPassword"] as String?
                val storeFile = keystoreProperties["storeFile"] as String?
                val storePassword = keystoreProperties["storePassword"] as String?
                
                // Debug: afficher les valeurs lues
                println("DEBUG - keyAlias: $keyAlias")
                println("DEBUG - keyPassword: ${if (keyPassword != null) "***" else "null"}")
                println("DEBUG - storeFile: $storeFile")
                println("DEBUG - storePassword: ${if (storePassword != null) "***" else "null"}")
                
                if (keyAlias != null && keyPassword != null && storeFile != null && storePassword != null) {
                    val resolvedStoreFile = rootProject.file(storeFile)
                    println("DEBUG - Chemin resolue du keystore: ${resolvedStoreFile.absolutePath}")
                    println("DEBUG - Keystore existe: ${resolvedStoreFile.exists()}")
                    
                    this.keyAlias = keyAlias
                    this.keyPassword = keyPassword
                    this.storeFile = resolvedStoreFile
                    this.storePassword = storePassword
                    println("✅ Configuration de signature release appliquee avec succes!")
                } else {
                    println("⚠️  ATTENTION: key.properties existe mais contient des valeurs manquantes. Utilisation de la signature de debug.")
                    println("   Valeurs manquantes: keyAlias=${keyAlias == null}, keyPassword=${keyPassword == null}, storeFile=${storeFile == null}, storePassword=${storePassword == null}")
                }
            } else {
                println("⚠️  ATTENTION: key.properties n'existe pas. Utilisation de la signature de debug.")
                println("📝 Pour créer un keystore de release, suivez les instructions dans INSTRUCTIONS_SIGNATURE.md")
            }
        }
    }

    buildTypes {
        getByName("release") {
            val releaseSigningConfig = signingConfigs.getByName("release")
            if (releaseSigningConfig.storeFile != null && releaseSigningConfig.storeFile!!.exists()) {
                signingConfig = releaseSigningConfig
            } else {
                println("⚠️  Utilisation de la signature de debug pour le build release.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.firebase:firebase-messaging:23.4.1")
    implementation("com.facebook.android:facebook-android-sdk:latest.release")
}
