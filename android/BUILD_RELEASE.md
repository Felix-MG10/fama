# 🚀 Construire l'application en mode Release

## ✅ Configuration actuelle

- ✅ Keystore : `android/upload-keystore.jks`
- ✅ Configuration : `android/key.properties`
- ✅ Build config : `android/app/build.gradle.kts` (corrigé)

## 📦 Construire le bundle Android (AAB) - Recommandé pour Google Play

```powershell
# Depuis la racine du projet
flutter clean
flutter build appbundle --release
```

Le fichier `.aab` sera créé dans :
```
build/app/outputs/bundle/release/app-release.aab
```

## 📱 Construire l'APK (alternative)

Si vous préférez un APK :

```powershell
flutter clean
flutter build apk --release
```

Le fichier `.apk` sera créé dans :
```
build/app/outputs/flutter-apk/app-release.apk
```

## 🔍 Vérifier la signature

Pour vérifier que votre application est bien signée avec la signature de release :

```powershell
# Pour un AAB
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# Pour un APK
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

Vous devriez voir `CN=upload` (votre alias) au lieu de `CN=Android Debug` dans la sortie.

## ⚠️ Important

- **Ne partagez jamais** votre fichier `key.properties` ou `upload-keystore.jks`
- **Conservez une copie de sauvegarde** de votre keystore dans un endroit sûr
- **Notez le mot de passe** dans un gestionnaire de mots de passe sécurisé

## 🎯 Prochaines étapes

1. Construisez le bundle avec `flutter build appbundle --release`
2. Uploadez le fichier `.aab` sur Google Play Console
3. Vous ne devriez plus voir l'erreur de signature en mode debug

---

*Configuration corrigée - Le chemin du keystore est maintenant résolu correctement*

