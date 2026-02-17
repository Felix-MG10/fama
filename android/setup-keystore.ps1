# Script interactif pour créer le keystore et configurer key.properties
# Usage: .\setup-keystore.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration de la Signature Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "upload-keystore.jks"
$keyPropertiesPath = "key.properties"
$alias = "upload"

# Vérifier si keytool est disponible
$keytoolPath = "C:\Program Files\Java\jdk-17\bin\keytool.exe"
if (-not (Test-Path $keytoolPath)) {
    $keytoolPath = Get-Command keytool -ErrorAction SilentlyContinue
    if ($keytoolPath) {
        $keytoolPath = $keytoolPath.Source
    } else {
        Write-Host "ERREUR: keytool n'a pas été trouvé!" -ForegroundColor Red
        Write-Host "Veuillez installer Java JDK." -ForegroundColor Yellow
        exit 1
    }
}

# Vérifier si le keystore existe déjà
if (Test-Path $keystorePath) {
    Write-Host "ATTENTION: Un keystore existe déjà: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Voulez-vous le remplacer? (oui/non)"
    if ($overwrite -ne "oui" -and $overwrite -ne "o" -and $overwrite -ne "y" -and $overwrite -ne "yes") {
        Write-Host "Opération annulée. Utilisation du keystore existant." -ForegroundColor Yellow
        $useExisting = $true
    } else {
        Remove-Item $keystorePath -Force
        $useExisting = $false
    }
} else {
    $useExisting = $false
}

if (-not $useExisting) {
    Write-Host ""
    Write-Host "Création du keystore..." -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous allez être invité à fournir les informations suivantes:" -ForegroundColor Yellow
    Write-Host "- Mot de passe du keystore (choisissez un mot de passe fort)" -ForegroundColor Yellow
    Write-Host "- Mot de passe de la clé (vous pouvez utiliser le même)" -ForegroundColor Yellow
    Write-Host "- Votre nom, organisation, ville, code pays" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Notez le mot de passe dans un endroit sûr!" -ForegroundColor Red
    Write-Host ""
    
    $command = "& '$keytoolPath' -genkey -v -keystore `"$keystorePath`" -keyalg RSA -keysize 2048 -validity 10000 -alias `"$alias`""
    
    try {
        Invoke-Expression $command
        
        if (-not (Test-Path $keystorePath)) {
            Write-Host "ERREUR: Le keystore n'a pas été créé." -ForegroundColor Red
            exit 1
        }
        
        Write-Host ""
        Write-Host "✅ Keystore créé avec succès!" -ForegroundColor Green
    } catch {
        Write-Host "ERREUR lors de la création du keystore:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# Demander le mot de passe pour créer key.properties
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration de key.properties" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $keyPropertiesPath) {
    Write-Host "ATTENTION: Le fichier key.properties existe déjà." -ForegroundColor Yellow
    $overwrite = Read-Host "Voulez-vous le remplacer? (oui/non)"
    if ($overwrite -ne "oui" -and $overwrite -ne "o" -and $overwrite -ne "y" -and $overwrite -ne "yes") {
        Write-Host "Conservation du fichier existant." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Entrez le mot de passe du keystore:" -ForegroundColor Yellow
$securePassword = Read-Host -AsSecureString
$storePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

Write-Host "Entrez le mot de passe de la clé (ou appuyez sur Entrée pour utiliser le même):" -ForegroundColor Yellow
$secureKeyPassword = Read-Host -AsSecureString
$keyPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKeyPassword))

if ([string]::IsNullOrWhiteSpace($keyPassword)) {
    $keyPassword = $storePassword
}

# Créer le fichier key.properties
$propertiesContent = @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$alias
storeFile=$keystorePath
"@

try {
    $propertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
    Write-Host ""
    Write-Host "✅ Fichier key.properties créé avec succès!" -ForegroundColor Green
} catch {
    Write-Host "ERREUR lors de la création de key.properties:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Configuration terminée!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers créés:" -ForegroundColor Cyan
Write-Host "  - $((Get-Item $keystorePath).FullName)" -ForegroundColor Gray
Write-Host "  - $((Get-Item $keyPropertiesPath).FullName)" -ForegroundColor Gray
Write-Host ""
Write-Host "Prochaines étapes:" -ForegroundColor Yellow
Write-Host "  1. Sauvegardez le keystore et les mots de passe en sécurité" -ForegroundColor Yellow
Write-Host "  2. Retournez à la racine du projet" -ForegroundColor Yellow
Write-Host "  3. Exécutez: flutter clean" -ForegroundColor Yellow
Write-Host "  4. Exécutez: flutter build appbundle --release" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  SAUVEGARDEZ LE KEYSTORE ET LES MOTS DE PASSE MAINTENANT!" -ForegroundColor Red

