# 📬 Test API OTP avec Postman

## ⚠️ IMPORTANT : Clarification

**Cette API backend NE PEUT PAS envoyer directement le SMS OTP.**

Le flux fonctionne ainsi :
1. ✅ **L'API backend** (`/api/v1/auth/login`) vérifie si le téléphone est vérifié
2. ✅ **L'application Flutter** lit la réponse : `is_phone_verified: 0`
3. ✅ **L'application Flutter** appelle **Firebase** pour envoyer le SMS OTP
4. ✅ **Firebase** envoie le SMS (pas l'API backend)

**Donc tester cette API dans Postman vous dira seulement si l'utilisateur doit vérifier son téléphone, mais ne vous enverra PAS de SMS.**

---

## 🔧 Configuration Postman

### **URL**
```
POST https://saphirauto.com/api/v1/auth/login
```

### **Headers**
```json
{
  "Content-Type": "application/json; charset=UTF-8",
  "X-localization": "fr",
  "latitude": "14.7232689",
  "longitude": "-17.4458174",
  "Authorization": "Bearer null",
  "zoneId": "[1]"
}
```

### **Body (JSON) - Pour OTP Login (première demande)**

```json
{
  "phone": "+221787954473",
  "login_type": "otp",
  "guest_id": ""
}
```

**OU** si vous avez un `guest_id` :

```json
{
  "phone": "+221787954473",
  "login_type": "otp",
  "guest_id": "69"
}
```

---

## 📋 Exemples de Requêtes

### **Exemple 1 : Premier appel OTP (demander le code)**

**URL :** `POST https://saphirauto.com/api/v1/auth/login`

**Headers :**
```
Content-Type: application/json; charset=UTF-8
X-localization: fr
latitude: 14.7232689
longitude: -17.4458174
Authorization: Bearer null
zoneId: [1]
```

**Body :**
```json
{
  "phone": "+221787954473",
  "login_type": "otp"
}
```

**Réponse attendue (200 OK) :**
```json
{
  "token": null,
  "is_phone_verified": 0,
  "is_email_verified": 1,
  "is_personal_info": 1,
  "is_exist_user": null,
  "login_type": "otp",
  "email": null
}
```

⚠️ **Cette réponse indique que le téléphone n'est PAS vérifié (`is_phone_verified: 0`), donc l'app doit appeler Firebase pour envoyer le SMS.**

---

### **Exemple 2 : Vérifier l'OTP reçu**

**Body :**
```json
{
  "phone": "+221787954473",
  "login_type": "otp",
  "otp": "123456",
  "verified": "firebase"  // ou la session Firebase ID
}
```

---

## 🔍 Test dans Postman

### **Étape 1 : Tester la première requête OTP**

1. Créez une nouvelle requête POST dans Postman
2. URL : `https://saphirauto.com/api/v1/auth/login`
3. Headers : Copiez ceux ci-dessus
4. Body (raw JSON) : 
   ```json
   {
     "phone": "+221787954473",
     "login_type": "otp"
   }
   ```
5. Envoyez la requête

**Résultat attendu :**
- Status : `200 OK`
- Response : `{"is_phone_verified": 0, ...}`

**Ce que cela signifie :**
- ✅ L'API fonctionne
- ✅ Le téléphone n'est pas vérifié
- ⚠️ **MAIS** le SMS ne sera PAS envoyé car seul Firebase peut le faire
- ⚠️ Le SMS sera envoyé **uniquement** si l'app appelle Firebase `verifyPhoneNumber()`

---

## 📱 Pour recevoir le SMS

Pour recevoir le SMS OTP, vous **DEVEZ** :
1. ✅ Tester dans l'**application mobile** (pas Postman)
2. ✅ L'application doit appeler Firebase `verifyPhoneNumber()`
3. ✅ Firebase enverra le SMS

**L'API backend seule ne peut pas envoyer de SMS.**

---

## 🧪 Tester Firebase directement dans l'app

Si vous voulez tester Firebase directement, créez un bouton de test dans votre app :

```dart
// Test Firebase OTP
ElevatedButton(
  onPressed: () async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+221787954473',
        verificationCompleted: (PhoneAuthCredential credential) {
          print('✅ Vérification automatique réussie');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Erreur: ${e.code} - ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ Code OTP envoyé ! ID: $verificationId');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Timeout: $verificationId');
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
    }
  },
  child: Text('Test Firebase OTP'),
)
```

---

## 📝 Résumé

| Test | Outil | Peut envoyer SMS ? |
|------|-------|-------------------|
| API `/api/v1/auth/login` | Postman | ❌ NON |
| Firebase `verifyPhoneNumber()` | Application mobile | ✅ OUI |

**Pour recevoir le SMS, testez dans l'application, pas dans Postman !** 📱


