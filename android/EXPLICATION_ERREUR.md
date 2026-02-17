# ❌ Explication de l'Erreur

## 📋 Erreur Rencontrée

```
Execution failed for task ':app:signReleaseBundle'.
Failed to read key upload from store "upload-keystore.jks": 
Keystore was tampered with, or password was incorrect
```

## 🔍 Signification

Cette erreur signifie que **le mot de passe dans `key.properties` ne correspond pas au mot de passe réel du keystore**.

### Situation Actuelle :
- ✅ Le keystore existe : `android/upload-keystore.jks`
- ✅ Le fichier `key.properties` existe
- ❌ Le mot de passe dans `key.properties` (`Passer@1`) n'est **PAS** le bon mot de passe du keystore

## ✅ Solutions

### **Solution 1 : Si vous connaissez le bon mot de passe**

Remplacez le contenu de `android/key.properties` avec le bon mot de passe :

```powershell
cd android
@"
storePassword=VOTRE_BON_MOT_DE_PASSE
keyPassword=VOTRE_BON_MOT_DE_PASSE
keyAlias=upload
storeFile=upload-keystore.jks
"@ | Out-File -FilePath "key.properties" -Encoding UTF8 -NoNewline
```

### **Solution 2 : Utiliser le script de correction**

```powershell
cd android
.\fix-keystore-password.ps1
```

Le script vous permettra de :
- Entrer le bon mot de passe si vous le connaissez
- Ou recréer le keystore si vous ne connaissez pas le mot de passe

⚠️ **ATTENTION** : Recréer le keystore invalide toutes les signatures précédentes. Ne faites cela QUE si vous n'avez pas encore publié l'app sur Google Play.

### **Solution 3 : Vérifier le mot de passe**

Pour tester si un mot de passe fonctionne :

```powershell
cd android
keytool -list -v -keystore upload-keystore.jks -storepass VOTRE_MOT_DE_PASSE -alias upload
```

Si cette commande réussit (sans erreur), alors le mot de passe est correct.

## 🚀 Après la Correction

Une fois le mot de passe corrigé :

```powershell
cd ..
flutter clean
flutter build appbundle --release
```

---

*Guide explicatif pour comprendre et résoudre l'erreur de mot de passe keystore*

