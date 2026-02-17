# 📱 Guide Complet : Configuration Firebase OTP

## ✅ Ce qui est déjà fait

- ✅ Projet Firebase créé : `fama-7db84`
- ✅ Phone Authentication activé
- ✅ `google-services.json` présent dans `android/app/`
- ✅ Firebase initialisé dans le code

---

## 🔧 Ce qu'il reste à faire

### **1. Ajouter SHA-1 et SHA-256 dans Firebase Console** ⚠️ **OBLIGATOIRE**

#### **Étape 1.1 : Générer les empreintes**

Exécutez le script que j'ai créé :
```powershell
.\android\app\obtenir-sha-keystore.ps1
```

Ce script va :
- Lire votre keystore `android/app/my-release-key.jks`
- Extraire SHA-1 et SHA-256
- Les copier dans le presse-papier

#### **Étape 1.2 : Ajouter dans Firebase Console**

1. Allez sur : https://console.firebase.google.com/project/fama-7db84/settings/general
2. Dans la section **"Your apps"**, sélectionnez votre app **Android** (`com.dakarapps.fama`)
3. Cliquez sur **"Add fingerprint"** (en bas de la page)
4. Ajoutez le **SHA-1** et cliquez sur **"Add"**
5. Ajoutez le **SHA-256** et cliquez sur **"Add"**
6. Cliquez sur **"Save"**

⚠️ **IMPORTANT :** Sans ces empreintes, Phone Authentication ne fonctionnera pas !

---

### **2. Configurer l'Admin Panel** 

#### **Étape 2.1 : Obtenir la Web API Key**

1. Allez sur : https://console.firebase.google.com/project/fama-7db84/settings/general
2. Dans la section **"Your apps"**, sélectionnez votre app **Web** (ou créez-en une si elle n'existe pas)
3. Copiez la **"Web API Key"** : `AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U`

#### **Étape 2.2 : Configurer dans l'Admin Panel**

1. Connectez-vous à votre Admin Panel
2. Allez dans **Settings > 3rd Party > Firebase OTP Verification**
3. Collez la **Web API Key** : `AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U`
4. **Activez** "Firebase OTP Verification Status"
5. **Activez** "Customer Verification" dans **Login Setup > Verification**

---

### **3. Configuration Web (si vous avez un site web)**

#### **Étape 3.1 : Ajouter le domaine autorisé**

1. Allez sur : https://console.firebase.google.com/project/fama-7db84/authentication/settings
2. Onglet **"Settings"**
3. Section **"Authorized domains"**
4. Cliquez sur **"Add domain"**
5. Ajoutez votre domaine (exemple : `saphirauto.com` - sans http/https)

---

### **4. Vérification iOS (si nécessaire)**

Si vous utilisez iOS, le fichier `GoogleService-Info.plist` est déjà présent. Vérifiez que `Info.plist` contient le `REVERSED_CLIENT_ID`.

---

## 🔑 Informations importantes trouvées dans votre projet

### **Web API Key :**
```
AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U
```
(Cette clé est déjà dans votre `main.dart` ligne 51)

### **Project ID :**
```
fama-7db84
```

### **Package Name :**
```
com.dakarapps.fama
```

---

## ✅ Checklist de vérification

- [ ] SHA-1 ajouté dans Firebase Console
- [ ] SHA-256 ajouté dans Firebase Console  
- [ ] Web API Key configuré dans Admin Panel
- [ ] Firebase OTP Verification Status activé dans Admin Panel
- [ ] Customer Verification activé dans Admin Panel
- [ ] Domaine web ajouté (si applicable)
- [ ] Plan Blaze activé dans Firebase (requis pour Phone Auth)

---

## 🚨 Points importants

1. **Plan Blaze requis** : Firebase Phone Authentication nécessite un plan Blaze (payant)
2. **SHA-1/SHA-256 obligatoires** : Sans ces empreintes, Phone Auth ne fonctionnera pas
3. **Cache à vider** : Après configuration, videz le cache de l'app pour charger la nouvelle config

---

## 📞 Test après configuration

Après avoir tout configuré :

1. Videz le cache : `adb shell pm clear com.dakarapps.fama`
2. Redémarrez l'application
3. Essayez de vous connecter avec OTP
4. Vous devriez recevoir le SMS

Les logs devraient afficher :
```
🔥 DEBUG OTP LOGIN - firebaseOtpVerification = true
✅ Appel Firebase verifyPhoneNumber pour OTP login
```

