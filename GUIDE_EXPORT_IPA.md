# 📦 Guide : Exporter l'IPA depuis l'Archive

## ✅ **Archive Créée avec Succès**

L'archive est disponible ici :
```
/Users/user278576/Desktop/farrynid/build/ios/archive/Runner.xcarchive
```

## 🎯 **Solution : Utiliser Xcode Organizer**

### **Étape 1 : Ouvrir Xcode Organizer**

L'archive devrait s'ouvrir automatiquement. Sinon :

1. Ouvrir **Xcode**
2. Menu : **Window → Organizer** (ou `Cmd + Shift + 9`)
3. Cliquer sur l'onglet **"Archives"**
4. Trouver l'archive **"Runner"** (date d'aujourd'hui)

### **Étape 2 : Distribuer l'App**

1. **Sélectionner l'archive** "Runner"
2. Cliquer sur **"Distribute App"** (bouton bleu en bas à droite)
3. Choisir une méthode de distribution :

#### **Option A : App Store Connect (Recommandé pour App Store)**
- Sélectionner **"App Store Connect"**
- Cliquer sur **"Next"**
- Choisir **"Upload"** (pour uploader directement)
- Ou **"Export"** (pour créer un fichier IPA local)
- Suivre l'assistant
- Xcode téléchargera automatiquement le certificat de distribution si nécessaire

#### **Option B : Ad Hoc (Pour tester)**
- Sélectionner **"Ad Hoc"**
- Cliquer sur **"Next"**
- Sélectionner les appareils de test
- Xcode créera l'IPA localement

#### **Option C : Development (Pour tester)**
- Sélectionner **"Development"**
- Cliquer sur **"Next"**
- Xcode créera l'IPA avec certificat de développement

### **Étape 3 : Si le Certificat est Manquant**

Si Xcode demande un certificat de distribution :

1. Dans Xcode : **Xcode → Settings → Accounts**
2. Sélectionner votre compte Apple Developer
3. Cliquer sur **"Manage Certificates"**
4. Cliquer sur **"+"** → **"Apple Distribution"**
5. Xcode créera automatiquement le certificat
6. Retourner à Organizer et réessayer

---

## 🔧 **Alternative : Utiliser Transporter**

Si vous avez déjà un IPA ou si vous exportez via Xcode :

1. Télécharger **Transporter** depuis l'App Store
2. Ouvrir Transporter
3. Glisser-déposer le fichier `.ipa` dans Transporter
4. Se connecter avec votre compte Apple Developer
5. Cliquer sur **"Deliver"**

---

## 📝 **Note Importante**

- L'archive est **déjà créée et valide**
- Il suffit de l'exporter via Xcode Organizer
- Xcode gérera automatiquement les certificats si votre compte est configuré
- Le certificat de distribution sera créé automatiquement si nécessaire

---

## ✅ **Vérification**

Après export, l'IPA sera disponible dans :
- **Upload** : Uploadé directement vers App Store Connect
- **Export** : `~/Desktop/farrynid/build/ios/ipa/Runner.ipa`

