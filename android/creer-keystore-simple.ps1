# Script simple pour créer le keystore avec des valeurs par défaut
# Usage: .\creer-keystore-simple.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Création du Keystore Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "upload-keystore.jks"
$alias = "upload"

# Vérifier si le keystore existe déjà
if (Test-Path $keystorePath) {
    Write-Host "ATTENTION: Un keystore existe déjà: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Voulez-vous le remplacer? (oui/non)"
    if ($overwrite -ne "oui" -and $overwrite -ne "o" -and $overwrite -ne "y" -and $overwrite -ne "yes") {
        Write-Host "Opération annulée." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $keystorePath -Force
}

Write-Host "Vous allez créer un keystore avec les informations suivantes:" -ForegroundColor Green
Write-Host ""
Write-Host "  Nom: Felix OMBAGHO" -ForegroundColor Gray
Write-Host "  Organisation: Dakarapps" -ForegroundColor Gray
Write-Host "  Ville: Dakar" -ForegroundColor Gray
Write-Host "  Pays: sn" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  IMPORTANT: Notez le mot de passe dans un endroit sûr!" -ForegroundColor Red
Write-Host ""
Write-Host "Lorsqu'on vous demande si les informations sont correctes, répondez: YES" -ForegroundColor Yellow
Write-Host ""

# Créer le keystore avec des valeurs par défaut pour éviter les questions
$keytoolPath = "C:\Program Files\Java\jdk-17\bin\keytool.exe"
if (-not (Test-Path $keytoolPath)) {
    $keytoolPath = Get-Command keytool -ErrorAction SilentlyContinue
    if ($keytoolPath) {
        $keytoolPath = $keytoolPath.Source
    } else {
        Write-Host "ERREUR: keytool n'a pas été trouvé!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Exécution de keytool..." -ForegroundColor Green
Write-Host ""

$command = "& '$keytoolPath' -genkey -v -keystore `"$keystorePath`" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias `"$alias`" -dname `"CN=Felix OMBAGHO, OU=Dakarapps, O=Dakarapps, L=Dakar, ST=Dakar, C=sn`""

try {
    # On ne peut pas utiliser -dname directement car keytool demande quand même confirmation
    # On va utiliser une méthode interactive
    Write-Host "Commande à exécuter manuellement:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "RÉPONDEZ AUX QUESTIONS:" -ForegroundColor Yellow
    Write-Host "  1. Mot de passe: (choisissez un mot de passe fort)" -ForegroundColor Gray
    Write-Host "  2. Nom: Felix OMBAGHO" -ForegroundColor Gray
    Write-Host "  3. Organisation: Dakarapps" -ForegroundColor Gray
    Write-Host "  4. Ville: Dakar" -ForegroundColor Gray
    Write-Host "  5. Pays: sn" -ForegroundColor Gray
    Write-Host "  6. Confirmer: YES (pas 'no' ou 'c'!)" -ForegroundColor Red
    Write-Host ""
    
    Read-Host "Appuyez sur Entrée quand vous êtes prêt à continuer..."
    
    # Exécuter la commande
    Invoke-Expression "& '$keytoolPath' -genkey -v -keystore `"$keystorePath`" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias `"$alias`""
    
    if (Test-Path $keystorePath) {
        Write-Host ""
        Write-Host "✅ Keystore créé avec succès!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Fichier: $((Get-Item $keystorePath).FullName)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Prochaine étape: Créez le fichier key.properties avec votre mot de passe" -ForegroundColor Yellow
    } else {
        Write-Host "ERREUR: Le keystore n'a pas été créé." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERREUR lors de la création du keystore:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

