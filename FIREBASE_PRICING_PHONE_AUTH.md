# 💰 Firebase Phone Authentication : Tarification

## ⚠️ IMPORTANT : Plan Requis

**Firebase Phone Authentication nécessite un plan Blaze (payant) pour fonctionner en production.**

---

## 📋 Plans Firebase

### **Plan Spark (GRATUIT)** ❌

- ❌ **NE SUPPORTE PAS** Phone Authentication
- ✅ Seulement pour développement/test (limites strictes)
- ✅ Autres services Firebase (Storage, Auth basique, etc.)

### **Plan Blaze (PAYANT)** ✅

- ✅ **REQUIS** pour Phone Authentication en production
- ✅ Modèle "Pay as you go" (vous payez ce que vous utilisez)
- ✅ Pas de frais mensuels fixes
- ✅ 50 000 authentifications gratuites par mois (au-delà = payant)

---

## 💵 Coûts Approximatifs

### **Coût par SMS de Vérification**

| Pays/Région | Coût par SMS (USD) |
|-------------|-------------------|
| USA | ~$0.06 |
| Canada | ~$0.05 |
| Europe | ~$0.03 - $0.05 |
| Afrique | Varie selon l'opérateur |
| Sénégal | ~$0.02 - $0.05 |

### **Gratuit chaque mois**

- **50 000 authentifications gratuites** par mois
- Au-delà, vous payez selon le coût du pays

**Exemple :**
- 100 SMS au Sénégal = **GRATUIT** (dans la limite gratuite)
- 60 000 SMS = 50 000 gratuits + 10 000 payants (~$200-500 selon pays)

---

## 🔍 Comment Vérifier Votre Plan Actuel

### **Étape 1 : Accéder à Firebase Console**

1. Allez sur : https://console.firebase.google.com/project/fama-7db84
2. Cliquez sur l'icône ⚙️ (Settings) en haut à gauche
3. Sélectionnez **"Usage and billing"**

### **Étape 2 : Vérifier Votre Plan**

- Si vous voyez **"Blaze plan"** → ✅ Vous pouvez utiliser Phone Auth
- Si vous voyez **"Spark plan"** → ❌ Vous devez upgrader

### **Étape 3 : Upgrader vers Blaze (si nécessaire)**

1. Dans **"Usage and billing"**
2. Cliquez sur **"Modify plan"** ou **"Upgrade to Blaze"**
3. Ajoutez une méthode de paiement (carte de crédit)
4. Confirmez l'upgrade

⚠️ **Important :** 
- Vous ne serez facturé que pour ce que vous utilisez
- Les 50 000 premières authentifications sont gratuites chaque mois
- Vous pouvez définir un budget d'alerte pour éviter les surprises

---

## 🎯 Pour Votre Cas (Sénégal)

Si vous envoyez des SMS au Sénégal :

- **Coût estimé** : ~$0.02 - $0.05 par SMS
- **Gratuit** : Les 50 000 premiers SMS/mois
- **Exemple** : 1 000 SMS/mois = **GRATUIT** ✅

---

## ✅ Vérification Rapide

**Test rapide pour savoir si votre plan est actif :**

1. Essayez de vous connecter avec OTP dans l'app
2. Si vous recevez un SMS → ✅ Plan Blaze actif
3. Si vous voyez une erreur liée au billing → ❌ Plan Spark, upgrade nécessaire

---

## 📝 Résumé

| Question | Réponse |
|----------|---------|
| Phone Auth est-il gratuit ? | ❌ Non, nécessite plan Blaze |
| Coût mensuel fixe ? | ❌ Non, pay as you go |
| Combien de SMS gratuits/mois ? | ✅ 50 000 |
| Coût par SMS au Sénégal ? | ~$0.02 - $0.05 |
| Peut-on tester gratuitement ? | ✅ Oui, jusqu'à 50 000/mois |

---

## 🔗 Liens Utils

- Firebase Pricing : https://firebase.google.com/pricing
- Phone Auth Pricing : https://firebase.google.com/docs/auth/phone-auth-pricing
- Billing Dashboard : https://console.firebase.google.com/project/fama-7db84/usage

---

**En résumé : Oui, vous devez avoir un plan Blaze, mais les 50 000 premiers SMS sont gratuits chaque mois !** 🎉


