# 🔍 Explication des Erreurs

## ✅ **Erreurs à Ignorer (Non-Critiques)**

### **1. CHHapticPattern Errors**
```
CHHapticPattern.mm:487: Failed to read pattern library data
```

**Explication :** Ces erreurs sont **normales** et peuvent être ignorées. Elles concernent les vibrations/haptics sur iOS et n'affectent pas le fonctionnement de l'application.

**Action :** Aucune action requise. Ce sont des logs système iOS.

---

### **2. nw_connection Errors**
```
nw_connection_copy_connected_local_endpoint_block_invoke: Connection has no local endpoint
```

**Explication :** Ces erreurs sont des **logs de debug réseau** normaux. Elles apparaissent lors des connexions réseau et n'indiquent pas un problème réel.

**Action :** Aucune action requise. Ce sont des logs de debug iOS.

---

## ❌ **Erreur Critique à Corriger**

### **3. API 403 - Undefined array key "id_token"**

```
flutter: ====> API Response: [403] /api/v1/auth/login
flutter: {error: wrong credential., message: Undefined array key "id_token"}
```

**Problème :** Le backend attend un champ `id_token` dans la requête de login, mais il n'est pas fourni.

**Cause :** Lors des connexions sociales (Google, Facebook, Apple), le modèle `SocialLogInBodyModel` envoie `token` mais le backend attend `id_token`.

**Solution Appliquée :** ✅

1. Ajout du champ `idToken` au modèle `SocialLogInBodyModel`
2. Modification de `toJson()` pour envoyer `id_token` avec la valeur de `token`
3. Le backend recevra maintenant `id_token` dans les requêtes de connexion sociale

**Fichier modifié :**
- `lib/features/auth/domain/models/social_log_in_body_model.dart`

**Résultat :** Les connexions sociales (Google, Facebook, Apple) devraient maintenant fonctionner correctement.

---

## 🧪 **Test de la Correction**

Après cette correction, testez :

1. **Connexion Google** : Devrait fonctionner sans erreur 403
2. **Connexion Facebook** : Devrait fonctionner sans erreur 403
3. **Connexion Apple** : Devrait fonctionner sans erreur 403

Si l'erreur persiste, vérifiez :
- Que le token est bien récupéré depuis le provider (Google/Facebook/Apple)
- Que le token n'est pas null ou vide
- Les logs pour voir ce qui est envoyé au backend

---

## 📝 **Note**

Les erreurs CHHapticPattern et nw_connection sont **normales** et peuvent être masquées si elles vous dérangent. Elles n'affectent pas le fonctionnement de l'application.

