# Signer l’app avec la même clé que sur le Dell (MacBook)

Le Play Store exige **la même clé** que celle utilisée pour les premiers uploads (empreinte attendue :  
`E7:32:53:45:A3:E5:D6:0C:19:EA:22:AA:52:DC:AA:C8:AD:59:03:FE`).

Sur le MacBook, sans cette clé, le build utilise la clé de debug (empreinte `33:FF:8F:5E:...`), ce qui provoque l’erreur « signé avec la mauvaise clé ».

## Étapes sur le MacBook

### 1. Récupérer le keystore depuis le Dell

- Sur ton **Dell**, le fichier keystore s’appelle en général **`upload-keystore.jks`** (ou `*.jks` / `*.keystore`).
- Il se trouve souvent dans le dossier du projet Android, par exemple :  
  `.../farrynid/android/upload-keystore.jks`
- **Copie ce fichier** (clé USB, cloud, etc.) vers ton **MacBook**.

### 2. Placer le keystore dans le projet sur le MacBook

- Colle le fichier **`upload-keystore.jks`** dans le dossier **`android/`** du projet sur le MacBook :
  ```
  farrynid/android/upload-keystore.jks
  ```

### 3. Créer `key.properties` sur le MacBook

- Dans le dossier **`android/`**, crée un fichier **`key.properties`** (s’il n’existe pas).
- Utilise **exactement les mêmes** mot de passe et alias que sur le Dell :

```properties
storePassword=LE_MEME_MOT_DE_PASSE_QUE_SUR_LE_DELL
keyPassword=LE_MEME_MOT_DE_PASSE_QUE_SUR_LE_DELL
keyAlias=upload
storeFile=upload-keystore.jks
```

- Remplace `LE_MEME_MOT_DE_PASSE_QUE_SUR_LE_DELL` par les vrais mots de passe (souvent identiques pour store et key).
- Si sur le Dell l’alias n’est pas `upload`, mets le même alias dans `keyAlias=`.

### 4. Vérifier l’empreinte (optionnel)

Pour confirmer que c’est bien la bonne clé (SHA1 attendu : `E7:32:53:45:...`) :

```bash
cd android
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Dans la sortie, l’empreinte **SHA1** doit être :  
`E7:32:53:45:A3:E5:D6:0C:19:EA:22:AA:52:DC:AA:C8:AD:59:03:FE`.

### 5. Rebuild du bundle

```bash
cd /chemin/vers/farrynid
flutter clean
flutter build appbundle --release
```

Le fichier **`build/app/outputs/bundle/release/app-release.aab`** sera alors signé avec la bonne clé et accepté par le Play Store.

---

**Important :**  
- Ne commite **jamais** `key.properties` ni `upload-keystore.jks` dans Git (ils sont déjà dans `.gitignore`).  
- Sans le fichier `.jks` du Dell, tu ne peux pas signer avec la clé attendue par le Play Store ; dans ce cas, il faudrait contacter le support Google Play (changement de clé = procédure spécifique).
