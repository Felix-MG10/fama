# Script pour corriger le problème de mot de passe du keystore
# Usage: .\corriger-mot-de-passe-keystore.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Correction du Mot de Passe Keystore" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "upload-keystore.jks"
$keyPropertiesPath = "key.properties"
$alias = "upload"

# Vérifier que le keystore existe
if (-not (Test-Path $keystorePath)) {
    Write-Host "ERREUR: Le keystore '$keystorePath' n'existe pas!" -ForegroundColor Red
    Write-Host "Vous devez d'abord créer un keystore." -ForegroundColor Yellow
    exit 1
}

# Trouver keytool
$keytoolPath = $null
if ($env:JAVA_HOME) {
    $keytoolPath = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    if (-not (Test-Path $keytoolPath)) {
        $keytoolPath = $null
    }
}

if (-not $keytoolPath) {
    $keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($keytoolCmd) {
        $keytoolPath = $keytoolCmd.Source
    }
}

if (-not $keytoolPath -or -not (Test-Path $keytoolPath)) {
    Write-Host "ERREUR: keytool n'a pas été trouvé!" -ForegroundColor Red
    Write-Host "Veuillez installer Java JDK." -ForegroundColor Yellow
    exit 1
}

Write-Host "Le keystore existe, mais le mot de passe dans key.properties ne correspond pas." -ForegroundColor Yellow
Write-Host ""
Write-Host "Vous avez deux options:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Si vous connaissez le bon mot de passe du keystore:" -ForegroundColor Green
Write-Host "   - Entrez-le maintenant et le fichier key.properties sera mis à jour" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Si vous ne connaissez pas le mot de passe:" -ForegroundColor Yellow
Write-Host "   - Le keystore sera recréé avec un nouveau mot de passe" -ForegroundColor Gray
Write-Host "   - ⚠️  ATTENTION: Cela invalidera les signatures précédentes" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Connaissez-vous le mot de passe actuel du keystore? (oui/non)"

if ($choice -eq "oui" -or $choice -eq "o" -or $choice -eq "y" -or $choice -eq "yes") {
    # Option 1: Mettre à jour key.properties avec le bon mot de passe
    Write-Host ""
    Write-Host "Entrez le mot de passe du keystore:" -ForegroundColor Yellow
    $securePassword = Read-Host -AsSecureString
    $storePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    
    Write-Host ""
    Write-Host "Vérification du mot de passe..." -ForegroundColor Cyan
    
    # Tester le mot de passe
    $testCommand = "& '$keytoolPath' -list -v -keystore `"$keystorePath`" -storepass `"$storePassword`" -alias `"$alias`" 2>&1"
    $testResult = Invoke-Expression $testCommand 2>&1
    
    if ($LASTEXITCODE -eq 0 -or ($testResult -notmatch "password was incorrect" -and $testResult -notmatch "was tampered")) {
        Write-Host "✅ Mot de passe correct!" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Entrez le mot de passe de la clé (ou appuyez sur Entrée pour utiliser le même):" -ForegroundColor Yellow
        $secureKeyPassword = Read-Host -AsSecureString
        $keyPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKeyPassword))
        
        if ([string]::IsNullOrWhiteSpace($keyPassword)) {
            $keyPassword = $storePassword
        }
        
        # Mettre à jour key.properties
        $propertiesContent = @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$alias
storeFile=$keystorePath
"@
        
        try {
            $propertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
            Write-Host ""
            Write-Host "✅ Fichier key.properties mis à jour avec succès!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Vous pouvez maintenant reconstruire votre application:" -ForegroundColor Cyan
            Write-Host "  flutter clean" -ForegroundColor Gray
            Write-Host "  flutter build appbundle --release" -ForegroundColor Gray
        } catch {
            Write-Host "ERREUR lors de la mise à jour de key.properties:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ Mot de passe incorrect!" -ForegroundColor Red
        Write-Host "Le mot de passe que vous avez entré ne correspond pas au keystore." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Voulez-vous recréer le keystore avec un nouveau mot de passe?" -ForegroundColor Yellow
        $recreate = Read-Host "(oui/non)"
        
        if ($recreate -ne "oui" -and $recreate -ne "o" -and $recreate -ne "y" -and $recreate -ne "yes") {
            Write-Host "Opération annulée." -ForegroundColor Yellow
            exit 0
        }
        
        # Continuer avec la recréation
        $choice = "non"
    }
}

if ($choice -ne "oui" -and $choice -ne "o" -and $choice -ne "y" -and $choice -ne "yes") {
    # Option 2: Recréer le keystore
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Recréation du Keystore" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  ATTENTION: Cette opération va:" -ForegroundColor Red
    Write-Host "   - Supprimer l'ancien keystore" -ForegroundColor Red
    Write-Host "   - Créer un nouveau keystore avec un nouveau mot de passe" -ForegroundColor Red
    Write-Host "   - Toutes les applications signées avec l'ancien keystore ne pourront plus être mises à jour" -ForegroundColor Red
    Write-Host ""
    Write-Host "⏸️  Si vous avez déjà publié votre app sur Google Play, NE FAITES PAS CECI!" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Voulez-vous vraiment continuer? (tapez 'RECREER' pour confirmer)"
    
    if ($confirm -ne "RECREER") {
        Write-Host "Opération annulée." -ForegroundColor Yellow
        exit 0
    }
    
    # Sauvegarder l'ancien keystore
    $backupPath = "$keystorePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $keystorePath -Destination $backupPath
    Write-Host ""
    Write-Host "📦 Ancien keystore sauvegardé dans: $backupPath" -ForegroundColor Cyan
    
    # Supprimer l'ancien keystore
    Remove-Item $keystorePath -Force
    
    Write-Host ""
    Write-Host "Création d'un nouveau keystore..." -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous allez être invité à fournir:" -ForegroundColor Yellow
    Write-Host "- Un nouveau mot de passe (choisissez-en un fort et notez-le!)" -ForegroundColor Yellow
    Write-Host "- Votre nom, organisation, ville, code pays" -ForegroundColor Yellow
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
        Write-Host ""
        
        # Demander le mot de passe pour key.properties
        Write-Host "Entrez le mot de passe que vous venez d'utiliser pour créer le keystore:" -ForegroundColor Yellow
        $securePassword = Read-Host -AsSecureString
        $storePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
        
        Write-Host "Entrez le mot de passe de la clé (ou appuyez sur Entrée pour utiliser le même):" -ForegroundColor Yellow
        $secureKeyPassword = Read-Host -AsSecureString
        $keyPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKeyPassword))
        
        if ([string]::IsNullOrWhiteSpace($keyPassword)) {
            $keyPassword = $storePassword
        }
        
        # Créer key.properties
        $propertiesContent = @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$alias
storeFile=$keystorePath
"@
        
        $propertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
        Write-Host ""
        Write-Host "✅ Fichier key.properties créé avec succès!" -ForegroundColor Green
        
    } catch {
        Write-Host "ERREUR lors de la création du keystore:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Configuration terminée!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant reconstruire votre application:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  cd .." -ForegroundColor Gray
Write-Host "  flutter clean" -ForegroundColor Gray
Write-Host "  flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""

