#!/bin/bash
# Script bash pour créer un keystore Android
# Usage: ./create-keystore.sh

echo "========================================"
echo "  Création du Keystore Android"
echo "========================================"
echo ""

KEYSTORE_PATH="upload-keystore.jks"
ALIAS="upload"

# Vérifier si keytool est disponible
if ! command -v keytool &> /dev/null; then
    echo "ERREUR: keytool n'a pas été trouvé!"
    echo ""
    echo "Solutions:"
    echo "1. Installez Java JDK (version 8 ou supérieure)"
    echo "2. Ajoutez JAVA_HOME à vos variables d'environnement"
    exit 1
fi

# Vérifier si le keystore existe déjà
if [ -f "$KEYSTORE_PATH" ]; then
    echo "ATTENTION: Un keystore existe déjà à: $KEYSTORE_PATH"
    read -p "Voulez-vous le remplacer? (oui/non): " overwrite
    if [ "$overwrite" != "oui" ] && [ "$overwrite" != "o" ] && [ "$overwrite" != "y" ] && [ "$overwrite" != "yes" ]; then
        echo "Opération annulée."
        exit 0
    fi
    rm -f "$KEYSTORE_PATH"
fi

echo "Création du keystore..."
echo ""
echo "Vous allez être invité à fournir les informations suivantes:"
echo "- Mot de passe du keystore (choisissez un mot de passe fort)"
echo "- Mot de passe de la clé (vous pouvez utiliser le même)"
echo "- Nom et prénom"
echo "- Nom de l'organisation"
echo "- Nom de la ville"
echo "- Code pays (2 lettres, ex: SN)"
echo ""
echo "⚠️  IMPORTANT: Notez les mots de passe dans un endroit sûr!"
echo ""

keytool -genkey -v -keystore "$KEYSTORE_PATH" -keyalg RSA -keysize 2048 -validity 10000 -alias "$ALIAS"

if [ -f "$KEYSTORE_PATH" ]; then
    echo ""
    echo "========================================"
    echo "  Keystore créé avec succès!"
    echo "========================================"
    echo ""
    echo "Fichier: $(pwd)/$KEYSTORE_PATH"
    echo ""
    echo "Prochaines étapes:"
    echo "1. Créez le fichier android/key.properties avec vos mots de passe"
    echo "2. Consultez GUIDE_SIGNATURE_ANDROID.md pour plus de détails"
    echo ""
    echo "⚠️  Sauvegardez ce fichier et vos mots de passe en sécurité!"
else
    echo "ERREUR: Le keystore n'a pas été créé."
    exit 1
fi

