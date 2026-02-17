# 🍎 Guide : Comment obtenir les credentials Apple pour le backend

Ce guide vous explique étape par étape comment obtenir les 4 informations nécessaires pour configurer Apple Sign-In sur votre backend.

---

## 📋 **Prérequis**

- ✅ Un compte **Apple Developer** payant ($99/an)
- ✅ Accès au portail Apple Developer : https://developer.apple.com/

---

## 🔑 **1. TEAM ID** (Identifiant d'équipe)

### Comment l'obtenir :

1. **Connectez-vous sur Apple Developer :**
   - Allez sur : https://developer.apple.com/
   - Connectez-vous avec votre compte Apple Developer

2. **Trouvez votre Team ID :**
   - **Méthode 1 :** Cliquez sur votre nom en haut à droite → Regardez la section **"Membership"** → Vous verrez votre **Team ID**
   - **Méthode 2 :** Allez directement sur : https://developer.apple.com/account/ → Votre Team ID apparaît en haut de la page

3. **Format :**
   - 10 caractères alphanumériques (ex: `ABCD123456`)
   - C'est la valeur à mettre dans le champ **"Team id"** du formulaire

---

## 🆔 **2. CLIENT ID** (Service ID)

Le Client ID pour Apple Sign-In est un **Service ID** que vous devez créer.

### ⚠️ **IMPORTANT - Vérification préalable :**

Avant de créer le Service ID, assurez-vous que votre App ID `com.dakarapps.fama` a bien **"Sign In with Apple"** activé :

1. Allez dans **Identifiers** → **App IDs**
2. Cliquez sur **"XC com dakarapps fama"** (Identifier: `com.dakarapps.fama`)
3. Vérifiez que la case **"Sign In with Apple"** est cochée
4. Si ce n'est pas le cas, cochez-la et cliquez sur **"Save"**

### Comment créer le Service ID :

1. **Allez dans Identifiers :**
   - URL : https://developer.apple.com/account/resources/identifiers/list
   - Cliquez sur **"Identifiers"** dans le menu de gauche

2. **Créez un nouveau Service ID :**
   - Cliquez sur le bouton **"+"** en haut à gauche
   - Sélectionnez **"Services IDs"** → **"Continue"**

3. **Configurez le Service ID :**
   - **Description** : "Fama Sign In with Apple" (ou un nom de votre choix)
   - **Identifier** : 
     - Format recommandé : `com.dakarapps.fama.service`
     - ⚠️ **Important :** Il doit être unique et différent de votre Bundle ID
   - Cliquez sur **"Continue"** puis **"Register"**

4. **Activez Sign In with Apple :**
   - Cliquez sur le Service ID que vous venez de créer
   - Cochez la case **"Sign In with Apple"**
   - Cliquez sur **"Configure"**

5. **Configurez les paramètres :**
   - **Primary App ID** : Sélectionnez **"XC com dakarapps fama"** (`com.dakarapps.fama`)
   - **Website URLs** :
     - **Domains and Subdomains** : `saphirauto.com` (ou votre domaine)
   - **Return URLs** :
     - Cliquez sur **"Add"**
     - Entrez : `https://saphirauto.com/customer/auth/login/apple/callback` (ou votre URL de callback)
     - Cliquez sur **"Add"** puis **"Done"**
   - Cliquez sur **"Save"** puis **"Continue"** puis **"Save"**

6. **Récupérez le Service ID :**
   - Le **Service ID** que vous venez de créer est votre **Client ID**
   - Exemple : `com.dakarapps.fama.service`
   - C'est la valeur à mettre dans le champ **"Client id"** du formulaire

---

## 🔐 **3. KEY ID** (Identifiant de clé)

Le Key ID est créé lorsque vous générez une clé pour Sign In with Apple.

### Comment l'obtenir :

1. **Allez dans Keys :**
   - URL : https://developer.apple.com/account/resources/authkeys/list
   - Cliquez sur **"Keys"** dans le menu de gauche

2. **Créez une nouvelle clé :**
   - Cliquez sur le bouton **"+"** en haut à gauche
   - **Key Name** : "Fama Sign In with Apple Key" (ou un nom de votre choix)

3. **Activez Sign In with Apple :**
   - Cochez la case **"Sign In with Apple"**
   - Cliquez sur **"Configure"** à côté

4. **Configurez la clé :**
   - **Primary App ID** : Sélectionnez **"XC com dakarapps fama"** (`com.dakarapps.fama`)
   - Cliquez sur **"Save"**

5. **Enregistrez la clé :**
   - Cliquez sur **"Continue"**
   - Vérifiez les informations
   - Cliquez sur **"Register"**

6. **⚠️ IMPORTANT - Téléchargez la clé immédiatement :**
   - Sur la page de confirmation, vous verrez un message : **"Download your key"**
   - **Cliquez sur "Download"** pour télécharger le fichier `.p8`
   - ⚠️ **Vous ne pourrez télécharger ce fichier qu'une seule fois !**
   - Le fichier s'appellera : `AuthKey_XXXXXXXXXX.p8`
   - **Gardez ce fichier en sécurité !**

7. **Notez le Key ID :**
   - Après le téléchargement, vous verrez le **Key ID** dans la liste des clés
   - Il ressemble à : `ABCD123456` (10 caractères alphanumériques)
   - C'est la valeur à mettre dans le champ **"Key id"** du formulaire

---

## 📄 **4. SERVICE FILE** (Fichier .p8)

Le Service File est le fichier `.p8` que vous avez téléchargé à l'étape précédente.

### Comment l'obtenir :

1. **Localisez le fichier téléchargé :**
   - Il devrait être dans votre dossier **Téléchargements** (Downloads)
   - Nom du fichier : `AuthKey_XXXXXXXXXX.p8`
   - Exemple : `AuthKey_ABCD123456.p8`

2. **Gardez une copie de sécurité :**
   - ⚠️ **Ce fichier est unique et ne peut pas être régénéré !**
   - Faites une copie du fichier et stockez-la en sécurité
   - Ne le partagez jamais publiquement

3. **Pour le formulaire :**
   - Dans le champ **"Service file"** du formulaire backend
   - Cliquez sur **"Aucun fichier choisi"** ou le bouton de sélection de fichier
   - Sélectionnez le fichier `AuthKey_XXXXXXXXXX.p8` que vous avez téléchargé
   - Le fichier sera uploadé sur le serveur

---

## ✅ **Résumé - Informations pour le formulaire**

| Champ du formulaire | Valeur | Où l'obtenir |
|---------------------|--------|--------------|
| **Client id** | `com.dakarapps.fama.service` | Service ID créé dans Apple Developer → Identifiers |
| **Team id** | `ABCD123456` | Apple Developer → Votre compte → Membership |
| **Key id** | `EFGH789012` | Apple Developer → Keys → Key ID de la clé créée |
| **Service file** | `AuthKey_XXXXX.p8` | Fichier téléchargé lors de la création de la clé |

---

## 🔗 **Liens rapides**

- **Apple Developer Portal :** https://developer.apple.com/
- **Votre compte (Team ID) :** https://developer.apple.com/account/
- **Identifiers (Service ID) :** https://developer.apple.com/account/resources/identifiers/list
- **Keys (Key ID) :** https://developer.apple.com/account/resources/authkeys/list

---

## ⚠️ **Notes importantes**

1. **Sécurité :**
   - Ne partagez jamais le fichier `.p8` publiquement
   - Ne commitez jamais ce fichier dans Git
   - Gardez ces informations dans un gestionnaire de mots de passe sécurisé

2. **Si vous perdez le fichier .p8 :**
   - Vous devrez créer une nouvelle clé dans Apple Developer
   - L'ancienne clé restera valide jusqu'à expiration, mais vous ne pourrez plus la télécharger

3. **Vérification :**
   - Assurez-vous que votre App ID principal a bien **"Sign In with Apple"** activé
   - Vérifiez que le Service ID est correctement configuré avec le domaine et l'URL de callback

---

**Bon courage pour la configuration ! 🚀**

