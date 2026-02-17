# 🔧 Correction du Problème de Mot de Passe Keystore

## ❌ Erreur Rencontrée

```
Failed to read key upload from store "upload-keystore.jks": 
Keystore was tampered with, or password was incorrect
```

Cette erreur signifie que le mot de passe dans `key.properties` ne correspond pas au mot de passe réel du keystore.

## ✅ Solutions

### **Solution 1 : Si vous connaissez le bon mot de passe**

Utilisez le script de correction :

```powershell
cd android
.\corriger-mot-de-passe-keystore.ps1
```

Le script vous demandera :
1. Si vous connaissez le mot de passe actuel (répondez "oui")
2. D'entrer le bon mot de passe
3. Le fichier `key.properties` sera automatiquement mis à jour

### **Solution 2 : Mise à jour manuelle de key.properties**

Si vous connaissez le bon mot de passe, mettez-le directement dans `android/key.properties` :

```powershell
cd android
@"
storePassword=VOTRE_BON_MOT_DE_PASSE
keyPassword=VOTRE_BON_MOT_DE_PASSE
keyAlias=upload
storeFile=upload-keystore.jks
"@ | Out-File -FilePath "key.properties" -Encoding UTF8 -NoNewline
```

Remplacez `VOTRE_BON_MOT_DE_PASSE` par le vrai mot de passe.

### **Solution 3 : Recréer le keystore (⚠️ Attention!)**

**⚠️ NE FAITES CECI QUE SI :**
- Vous n'avez **PAS encore** publié l'application sur Google Play
- Ou vous acceptez de créer une nouvelle application sur Google Play (l'ancienne ne pourra plus être mise à jour)

Si c'est le cas, utilisez le script :

```powershell
cd android
.\corriger-mot-de-passe-keystore.ps1
```

Répondez "non" à la question sur le mot de passe, puis confirmez la recréation.

## 🚀 Après la Correction

Une fois le problème résolu :

```powershell
cd ..
flutter clean
flutter build appbundle --release
```

Le build devrait maintenant fonctionner avec la signature de release ! ✅

## 🔍 Vérification

Pour tester si le mot de passe est correct :

```powershell
cd android
keytool -list -v -keystore upload-keystore.jks -storepass VOTRE_MOT_DE_PASSE -alias upload
```

Si la commande réussit sans erreur, le mot de passe est correct.

---

*Guide pour résoudre les problèmes de mot de passe keystore*

