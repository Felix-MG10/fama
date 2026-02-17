# 🔧 Guide de Dépannage : Pourquoi le bouton Apple Sign-In n'apparaît pas ?

## 🔍 Conditions requises pour afficher le bouton Apple Sign-In

Le bouton Apple Sign-In n'apparaît que si **TOUTES** ces conditions sont remplies :

### ✅ **Condition 1 : Plateforme iOS uniquement**
- ❌ **Android** : Le bouton n'apparaîtra JAMAIS
- ❌ **Web** : Le bouton n'apparaîtra JAMAIS
- ✅ **iOS (iPhone/iPad)** : Le bouton peut apparaître si les autres conditions sont remplies

### ✅ **Condition 2 : Configuration backend activée**
- Le backend doit retourner `appleLogin` dans la réponse de `/api/v1/config`
- `appleLogin[0].status` doit être `1` (activé) ou `true`

### ✅ **Condition 3 : Tableau appleLogin non vide**
- Le tableau `appleLogin` ne doit pas être vide dans la réponse API

---

## 🔎 **Comment vérifier et résoudre le problème**

### **Étape 1 : Vérifier la plateforme**

**Question :** Sur quelle plateforme testez-vous l'application ?

- ✅ **Si vous testez sur iOS (simulateur ou appareil réel)** → Continuez à l'étape 2
- ❌ **Si vous testez sur Android** → Le bouton n'apparaîtra jamais (c'est normal)
- ❌ **Si vous testez sur Web** → Le bouton n'apparaîtra jamais (c'est normal)

**Code de vérification :**
```dart
// Dans social_login_widget.dart ligne 35-36
bool canAppleLogin = 
  Get.find<SplashController>().configModel!.appleLogin!.isNotEmpty 
  && Get.find<SplashController>().configModel!.appleLogin![0].status!
  && !GetPlatform.isAndroid  // ← Doit être false (pas Android)
  && !GetPlatform.isWeb;     // ← Doit être false (pas Web)
```

---

### **Étape 2 : Vérifier la configuration backend**

**Vérifiez la réponse de l'API `/api/v1/config` :**

1. **Ouvrez votre backend** ou utilisez un outil comme Postman
2. **Faites une requête GET** vers : `https://votre-backend.com/api/v1/config`
3. **Vérifiez la réponse JSON** - elle doit contenir :

```json
{
  "apple_login": [
    {
      "login_medium": "apple",
      "status": 1,  // ← DOIT être 1 (activé)
      "client_id": "com.dakarapps.fama.service"  // ou votre Service ID
    }
  ],
  "apple_login_status": 1  // ← DOIT être 1 (activé)
}
```

**⚠️ Problèmes possibles :**

| Problème | Solution |
|----------|----------|
| `apple_login` est absent | Ajoutez la configuration Apple dans votre backend |
| `apple_login` est un tableau vide `[]` | Ajoutez au moins un élément dans le tableau |
| `status: 0` ou `status: false` | Activez Apple Sign-In dans votre panel admin backend |
| `apple_login_status: 0` | Activez le statut global Apple dans votre backend |

---

### **Étape 3 : Configurer Apple Sign-In dans le backend**

**Si la configuration n'existe pas ou est désactivée :**

1. **Connectez-vous à votre panel admin backend**
2. **Allez dans la section de configuration des connexions sociales**
3. **Trouvez la section "Apple Sign-In" ou "Apple Login"**
4. **Activez Apple Sign-In** :
   - Cochez "Activer Apple Sign-In" ou mettez `status: 1`
   - Remplissez les champs requis :
     - **Client ID** : `com.dakarapps.fama.service` (votre Service ID)
     - **Team ID** : `FYX2W82CVC` (votre Team ID)
     - **Key ID** : (votre Key ID)
     - **Service File** : (uploader le fichier `.p8`)
5. **Sauvegardez la configuration**
6. **Redémarrez l'application** pour recharger la configuration

---

### **Étape 4 : Vérifier dans le code Flutter**

**Ajoutez des logs de débogage pour vérifier :**

Vous pouvez temporairement ajouter ces logs dans `social_login_widget.dart` :

```dart
@override
Widget build(BuildContext context) {
  // ... code existant ...
  
  // AJOUTEZ CES LOGS POUR DÉBOGUER
  print('🔍 DEBUG Apple Sign-In:');
  print('  - Platform is Android: ${GetPlatform.isAndroid}');
  print('  - Platform is Web: ${GetPlatform.isWeb}');
  print('  - appleLogin isNotEmpty: ${Get.find<SplashController>().configModel!.appleLogin!.isNotEmpty}');
  if (Get.find<SplashController>().configModel!.appleLogin!.isNotEmpty) {
    print('  - appleLogin[0].status: ${Get.find<SplashController>().configModel!.appleLogin![0].status}');
  }
  print('  - canAppleLogin: $canAppleLogin');
  
  // ... reste du code ...
}
```

**Exécutez l'application et regardez les logs dans la console.**

---

## 📋 **Checklist de vérification**

Cochez chaque point pour identifier le problème :

- [ ] **Je teste sur iOS** (simulateur ou appareil réel)
- [ ] **Je ne teste PAS sur Android**
- [ ] **Je ne teste PAS sur Web**
- [ ] **L'API `/api/v1/config` retourne `apple_login`**
- [ ] **`apple_login` n'est pas un tableau vide**
- [ ] **`apple_login[0].status` est `1` ou `true`**
- [ ] **`apple_login_status` est `1` ou `true`**
- [ ] **J'ai configuré Apple Sign-In dans le backend avec les credentials**
- [ ] **J'ai redémarré l'application après avoir activé Apple Sign-In**

---

## 🚨 **Problèmes courants et solutions**

### **Problème 1 : Le bouton n'apparaît pas sur iOS**

**Causes possibles :**
- La configuration backend n'est pas activée
- Le tableau `appleLogin` est vide
- `appleLogin[0].status` est `0` ou `false`

**Solution :**
1. Vérifiez la réponse de l'API `/api/v1/config`
2. Activez Apple Sign-In dans votre panel admin backend
3. Redémarrez l'application

---

### **Problème 2 : Erreurs de haptique (non bloquant)**

Les erreurs que vous voyez :
```
Error Domain=NSCocoaErrorDomain Code=260 "The file "hapticpatternlibrary.plist" couldn't be opened
```

**Ce n'est PAS un problème !** Ces erreurs sont normales sur le simulateur iOS et n'empêchent pas Apple Sign-In de fonctionner. Vous pouvez les ignorer.

---

### **Problème 3 : Configuration backend incomplète**

**Si vous n'avez pas encore configuré Apple Sign-In dans le backend :**

1. Suivez le guide : `GUIDE_OBTENIR_CREDENTIALS_APPLE.md`
2. Obtenez les 4 informations nécessaires :
   - Client ID (Service ID)
   - Team ID (`FYX2W82CVC` - vous l'avez déjà)
   - Key ID
   - Service File (.p8)
3. Configurez-les dans votre panel admin backend
4. Activez Apple Sign-In (`status: 1`)

---

## 🔗 **Fichiers à vérifier**

1. **Configuration backend :**
   - Panel admin backend → Configuration → Connexions sociales → Apple Sign-In

2. **Code Flutter :**
   - `lib/features/auth/widgets/social_login_widget.dart` (lignes 35-36, 98-119, 208-223)

3. **Modèle de configuration :**
   - `lib/features/splash/domain/models/config_model.dart`

4. **API endpoint :**
   - `GET /api/v1/config` (doit retourner `apple_login`)

---

## ✅ **Résumé**

Le bouton Apple Sign-In n'apparaît que si :
1. ✅ Vous êtes sur **iOS** (pas Android, pas Web)
2. ✅ Le backend retourne `apple_login` avec `status: 1`
3. ✅ Le tableau `apple_login` n'est pas vide

**Si le bouton n'apparaît toujours pas après avoir vérifié tout cela, ajoutez les logs de débogage et vérifiez les valeurs dans la console.**

---

**Besoin d'aide supplémentaire ?** Vérifiez les logs de débogage et partagez la réponse de l'API `/api/v1/config`.

