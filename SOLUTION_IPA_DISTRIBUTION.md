# 🔧 Solution : Erreur "No signing certificate iOS Distribution"

## ❌ **Problème**

L'archive est créée avec succès, mais l'export IPA échoue car il n'y a pas de certificat "iOS Distribution" dans le Keychain.

**Erreur :**
```
error: exportArchive No signing certificate "iOS Distribution" found
```

## ✅ **Solution 1 : Utiliser Xcode pour Distribuer (Recommandé)**

L'archive est déjà créée dans :
```
/Users/user278576/Desktop/farrynid/build/ios/archive/Runner.xcarchive
```

### **Étapes :**

1. **Ouvrir l'archive dans Xcode :**
   ```bash
   open /Users/user278576/Desktop/farrynid/build/ios/archive/Runner.xcarchive
   ```

2. **Dans Xcode Organizer :**
   - L'archive s'ouvrira automatiquement
   - Cliquez sur **"Distribute App"**
   - Sélectionnez **"App Store Connect"**
   - Suivez les étapes de l'assistant
   - Xcode téléchargera automatiquement le certificat de distribution si nécessaire

3. **Alternative : Export Manually**
   - Dans Xcode Organizer, sélectionnez l'archive
   - Cliquez sur **"Distribute App"**
   - Choisissez **"Ad Hoc"** ou **"Development"** si vous voulez juste tester
   - Ou **"App Store Connect"** pour uploader vers App Store

---

## ✅ **Solution 2 : Créer le Certificat de Distribution**

### **Via Xcode :**

1. Ouvrir Xcode
2. **Xcode → Settings → Accounts**
3. Sélectionner votre compte Apple Developer
4. Cliquer sur **"Manage Certificates"**
5. Cliquer sur **"+"** → **"Apple Distribution"**
6. Xcode créera automatiquement le certificat

### **Via App Store Connect :**

1. Aller sur https://appstoreconnect.apple.com
2. **Users and Access → Keys**
3. Créer une nouvelle clé si nécessaire
4. Télécharger le certificat

---

## ✅ **Solution 3 : Utiliser Flutter avec Export Options**

Créer un fichier `ExportOptions.plist` :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>FYX2W82CVC</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

Puis utiliser :
```bash
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ExportOptions.plist
```

---

## 🎯 **Solution Rapide (Recommandée)**

**Utilisez Xcode directement :**

```bash
open /Users/user278576/Desktop/farrynid/build/ios/archive/Runner.xcarchive
```

Puis dans Xcode Organizer :
1. Sélectionnez l'archive
2. Cliquez sur **"Distribute App"**
3. Choisissez **"App Store Connect"**
4. Xcode gérera automatiquement les certificats

---

## 📝 **Note**

L'archive est déjà créée et valide. Il suffit de l'exporter via Xcode qui téléchargera automatiquement le certificat de distribution si votre compte Apple Developer est correctement configuré.

