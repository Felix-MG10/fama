# ✅ Checklist : Configuration Firebase OTP

## 📋 État Actuel

- [x] **Projet Firebase créé** : `fama-7db84`
- [x] **Phone Authentication activé** dans Firebase Console
- [x] **google-services.json** mis à jour avec nouveau SHA-1
- [x] **SHA-1 ajouté** dans Firebase Console (certificate_hash: e7325345...)
- [ ] **SHA-256 ajouté** dans Firebase Console (à vérifier)
- [ ] **Admin Panel configuré** (EN COURS)
- [ ] **Cache vidé** (à faire)
- [ ] **Application rebuild** (à faire)

---

## 🔧 Actions Restantes

### **1. Vérifier SHA-256 dans Firebase Console**

URL : https://console.firebase.google.com/project/fama-7db84/settings/general

Vérifiez que vous avez ajouté **LES DEUX** :
- ✅ SHA-1 : `e7325345a3e5d60c19ea22aa52dcaac8ad5903fe` (déjà fait)
- ❓ SHA-256 : (à vérifier si ajouté)

---

### **2. Configurer Admin Panel** ⚠️ **CRITIQUE**

**Informations nécessaires :**
- **Web API Key** : `AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U`

**Étapes :**
1. Connectez-vous à votre Admin Panel
2. Allez dans **Settings > 3rd Party > Firebase OTP Verification**
3. Collez la **Web API Key** : `AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U`
4. ✅ **Activez** "Firebase OTP Verification Status" (bouton ON)
5. Allez dans **Login Setup > Verification**
6. ✅ **Activez** "Customer Verification" (bouton ON)
7. Sauvegardez

**Vérification :**
Après configuration, vérifiez l'API :
- https://saphirauto.com/api/v1/config
- Cherchez : `"firebase_otp_verification": 1` ✅

---

### **3. Vider le Cache de l'Application**

**Option 1 : Via ADB**
```bash
adb shell pm clear com.dakarapps.fama
```

**Option 2 : Manuellement**
- Settings → Apps → Fama → Storage → Clear Data

---

### **4. Rebuild l'Application**

```bash
flutter clean
flutter build appbundle --release
```

Ou pour tester rapidement :
```bash
flutter run --release
```

---

## 🎯 Vérification Finale

Après avoir tout configuré :

1. ✅ **Videz le cache** de l'app
2. ✅ **Redémarrez** l'application
3. ✅ **Testez** la connexion avec OTP
4. ✅ **Vérifiez les logs** :

Vous devriez voir :
```
🔥 DEBUG OTP LOGIN - firebaseOtpVerification = true
✅ Appel Firebase verifyPhoneNumber pour OTP login
```

Si vous voyez toujours `firebaseOtpVerification = false`, c'est que :
- L'Admin Panel n'est pas encore configuré
- OU le cache n'a pas été vidé

---

## 📝 Notes Importantes

1. **Plan Blaze requis** : Firebase Phone Auth nécessite un plan payant
2. **Les deux SHA sont nécessaires** : SHA-1 ET SHA-256 doivent être ajoutés
3. **Le cache doit être vidé** après chaque changement de configuration
4. **Rebuild nécessaire** après modification de `google-services.json`

