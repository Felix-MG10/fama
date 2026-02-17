# 📋 Résumé Rapide : Configuration Firebase OTP

## 🎯 Ce que vous devez faire MAINTENANT

### **1. Générer SHA-1 et SHA-256**

```powershell
.\android\app\obtenir-sha-keystore.ps1
```

### **2. Ajouter dans Firebase Console**

URL : https://console.firebase.google.com/project/fama-7db84/settings/general

1. Sélectionnez votre app Android
2. Cliquez sur "Add fingerprint"
3. Ajoutez SHA-1 et SHA-256
4. Sauvegardez

### **3. Configurer Admin Panel**

1. Web API Key à utiliser : `AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U`
2. Settings > 3rd Party > Firebase OTP Verification
3. Collez la Web API Key
4. Activez "Firebase OTP Verification Status"
5. Activez "Customer Verification" dans Login Setup > Verification

---

## 🔍 Réponse à votre question sur Google Sign-In

**"je dois faire quoi sur firebase: Google"**

Pour **Phone Authentication**, vous n'avez PAS besoin de configurer Google Sign-In séparément. 

L'avertissement que vous voyez concerne :
- ✅ **Google Sign-In** (pour se connecter avec un compte Google)
- ❌ **Phone Authentication** (pour les SMS OTP) - **C'est différent !**

**Pour Phone Authentication :**
- Vous devez juste ajouter les **SHA-1 et SHA-256** dans Firebase Console
- C'est tout ! (plus la configuration dans l'Admin Panel)

---

## 📝 Prochaines étapes après configuration

1. Vider le cache de l'app
2. Redémarrer l'application  
3. Tester la connexion OTP
4. Vérifier que le SMS arrive

