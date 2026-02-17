# Script PowerShell pour créer un keystore Android
# Usage: .\create-keystore.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Création du Keystore Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "upload-keystore.jks"
$alias = "upload"

# Vérifier si keytool est disponible
$keytoolPath = $null
$javaHome = $env:JAVA_HOME

if ($javaHome) {
    $keytoolPath = Join-Path $javaHome "bin\keytool.exe"
    if (-not (Test-Path $keytoolPath)) {
        $keytoolPath = $null
    }
}

if (-not $keytoolPath) {
    # Essayer de trouver keytool dans le PATH
    $keytoolPath = Get-Command keytool -ErrorAction SilentlyContinue
    if ($keytoolPath) {
        $keytoolPath = $keytoolPath.Source
    }
}

if (-not $keytoolPath -or -not (Test-Path $keytoolPath)) {
    Write-Host "ERREUR: keytool n'a pas été trouvé!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host "1. Installez Java JDK (version 8 ou supérieure)" -ForegroundColor Yellow
    Write-Host "2. Ajoutez JAVA_HOME à vos variables d'environnement" -ForegroundColor Yellow
    Write-Host "3. Ou exécutez manuellement cette commande:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload" -ForegroundColor Gray
    exit 1
}

# Vérifier si le keystore existe déjà
if (Test-Path $keystorePath) {
    Write-Host "ATTENTION: Un keystore existe déjà à: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Voulez-vous le remplacer? (oui/non)"
    if ($overwrite -ne "oui" -and $overwrite -ne "o" -and $overwrite -ne "y" -and $overwrite -ne "yes") {
        Write-Host "Opération annulée." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $keystorePath -Force
}

Write-Host "Création du keystore..." -ForegroundColor Green
Write-Host ""
Write-Host "Vous allez être invité à fournir les informations suivantes:" -ForegroundColor Yellow
Write-Host "- Mot de passe du keystore (choisissez un mot de passe fort)" -ForegroundColor Yellow
Write-Host "- Mot de passe de la clé (vous pouvez utiliser le même)" -ForegroundColor Yellow
Write-Host "- Nom et prénom" -ForegroundColor Yellow
Write-Host "- Nom de l'organisation" -ForegroundColor Yellow
Write-Host "- Nom de la ville" -ForegroundColor Yellow
Write-Host "- Code pays (2 lettres, ex: SN)" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  IMPORTANT: Notez les mots de passe dans un endroit sûr!" -ForegroundColor Red
Write-Host ""

$command = "& '$keytoolPath' -genkey -v -keystore `"$keystorePath`" -keyalg RSA -keysize 2048 -validity 10000 -alias `"$alias`""

try {
    Invoke-Expression $command
    
    if (Test-Path $keystorePath) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  Keystore créé avec succès!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Fichier: $((Get-Item $keystorePath).FullName)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Prochaines étapes:" -ForegroundColor Yellow
        Write-Host "1. Créez le fichier android/key.properties avec vos mots de passe" -ForegroundColor Yellow
        Write-Host "2. Consultez GUIDE_SIGNATURE_ANDROID.md pour plus de détails" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "⚠️  Sauvegardez ce fichier et vos mots de passe en sécurité!" -ForegroundColor Red
    } else {
        Write-Host "ERREUR: Le keystore n'a pas été créé." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERREUR lors de la création du keystore:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

