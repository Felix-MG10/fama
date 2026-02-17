# Script pour corriger le probleme de mot de passe du keystore
# Usage: .\fix-keystore-password.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Correction du Mot de Passe Keystore" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "upload-keystore.jks"
$keyPropertiesPath = "key.properties"
$alias = "upload"

# Verifier que le keystore existe
if (-not (Test-Path $keystorePath)) {
    Write-Host "ERREUR: Le keystore '$keystorePath' n'existe pas!" -ForegroundColor Red
    Write-Host "Vous devez d'abord creer un keystore." -ForegroundColor Yellow
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
    Write-Host "ERREUR: keytool n'a pas ete trouve!" -ForegroundColor Red
    Write-Host "Veuillez installer Java JDK." -ForegroundColor Yellow
    exit 1
}

Write-Host "Le keystore existe, mais le mot de passe dans key.properties ne correspond pas." -ForegroundColor Yellow
Write-Host ""
Write-Host "Vous avez deux options:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Si vous connaissez le bon mot de passe du keystore:" -ForegroundColor Green
Write-Host "   - Entrez-le maintenant et le fichier key.properties sera mis a jour" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Si vous ne connaissez pas le mot de passe:" -ForegroundColor Yellow
Write-Host "   - Le keystore sera recree avec un nouveau mot de passe" -ForegroundColor Gray
Write-Host "   - ATTENTION: Cela invalidera les signatures precedentes" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Connaissez-vous le mot de passe actuel du keystore? (oui/non)"

if ($choice -eq "oui" -or $choice -eq "o" -or $choice -eq "y" -or $choice -eq "yes") {
    # Option 1: Mettre a jour key.properties avec le bon mot de passe
    Write-Host ""
    Write-Host "Entrez le mot de passe du keystore:" -ForegroundColor Yellow
    $securePassword = Read-Host -AsSecureString
    $storePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    
    Write-Host ""
    Write-Host "Verification du mot de passe..." -ForegroundColor Cyan
    
    # Tester le mot de passe
    $testResult = & $keytoolPath -list -v -keystore $keystorePath -storepass $storePassword -alias $alias 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Mot de passe correct!" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Entrez le mot de passe de la cle (ou appuyez sur Entree pour utiliser le meme):" -ForegroundColor Yellow
        $secureKeyPassword = Read-Host -AsSecureString
        $keyPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKeyPassword))
        
        if ([string]::IsNullOrWhiteSpace($keyPassword)) {
            $keyPassword = $storePassword
        }
        
        # Mettre a jour key.properties
        $propertiesContent = "storePassword=$storePassword`nkeyPassword=$keyPassword`nkeyAlias=$alias`nstoreFile=$keystorePath`n"
        
        try {
            $propertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
            Write-Host ""
            Write-Host "Fichier key.properties mis a jour avec succes!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Vous pouvez maintenant reconstruire votre application:" -ForegroundColor Cyan
            Write-Host "  flutter clean" -ForegroundColor Gray
            Write-Host "  flutter build appbundle --release" -ForegroundColor Gray
        } catch {
            Write-Host "ERREUR lors de la mise a jour de key.properties:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Mot de passe incorrect!" -ForegroundColor Red
        Write-Host "Le mot de passe que vous avez entre ne correspond pas au keystore." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Voulez-vous recreer le keystore avec un nouveau mot de passe?" -ForegroundColor Yellow
        $recreate = Read-Host "(oui/non)"
        
        if ($recreate -ne "oui" -and $recreate -ne "o" -and $recreate -ne "y" -and $recreate -ne "yes") {
            Write-Host "Operation annulee." -ForegroundColor Yellow
            exit 0
        }
        
        # Continuer avec la recreation
        $choice = "non"
    }
}

if ($choice -ne "oui" -and $choice -ne "o" -and $choice -ne "y" -and $choice -ne "yes") {
    # Option 2: Recreer le keystore
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Recreation du Keystore" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ATTENTION: Cette operation va:" -ForegroundColor Red
    Write-Host "   - Supprimer l'ancien keystore" -ForegroundColor Red
    Write-Host "   - Creer un nouveau keystore avec un nouveau mot de passe" -ForegroundColor Red
    Write-Host "   - Toutes les applications signees avec l'ancien keystore ne pourront plus etre mises a jour" -ForegroundColor Red
    Write-Host ""
    Write-Host "Si vous avez deja publie votre app sur Google Play, NE FAITES PAS CECI!" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Voulez-vous vraiment continuer? (tapez 'RECREER' pour confirmer)"
    
    if ($confirm -ne "RECREER") {
        Write-Host "Operation annulee." -ForegroundColor Yellow
        exit 0
    }
    
    # Sauvegarder l'ancien keystore
    $backupPath = "$keystorePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $keystorePath -Destination $backupPath
    Write-Host ""
    Write-Host "Ancien keystore sauvegarde dans: $backupPath" -ForegroundColor Cyan
    
    # Supprimer l'ancien keystore
    Remove-Item $keystorePath -Force
    
    Write-Host ""
    Write-Host "Creation d'un nouveau keystore..." -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous allez etre invite a fournir:" -ForegroundColor Yellow
    Write-Host "- Un nouveau mot de passe (choisissez-en un fort et notez-le!)" -ForegroundColor Yellow
    Write-Host "- Votre nom, organisation, ville, code pays" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        & $keytoolPath -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias $alias
        
        if (-not (Test-Path $keystorePath)) {
            Write-Host "ERREUR: Le keystore n'a pas ete cree." -ForegroundColor Red
            exit 1
        }
        
        Write-Host ""
        Write-Host "Keystore cree avec succes!" -ForegroundColor Green
        Write-Host ""
        
        # Demander le mot de passe pour key.properties
        Write-Host "Entrez le mot de passe que vous venez d'utiliser pour creer le keystore:" -ForegroundColor Yellow
        $securePassword = Read-Host -AsSecureString
        $storePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
        
        Write-Host "Entrez le mot de passe de la cle (ou appuyez sur Entree pour utiliser le meme):" -ForegroundColor Yellow
        $secureKeyPassword = Read-Host -AsSecureString
        $keyPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKeyPassword))
        
        if ([string]::IsNullOrWhiteSpace($keyPassword)) {
            $keyPassword = $storePassword
        }
        
        # Creer key.properties
        $propertiesContent = "storePassword=$storePassword`nkeyPassword=$keyPassword`nkeyAlias=$alias`nstoreFile=$keystorePath`n"
        
        $propertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
        Write-Host ""
        Write-Host "Fichier key.properties cree avec succes!" -ForegroundColor Green
        
    } catch {
        Write-Host "ERREUR lors de la creation du keystore:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Configuration terminee!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant reconstruire votre application:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  cd .." -ForegroundColor Gray
Write-Host "  flutter clean" -ForegroundColor Gray
Write-Host "  flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""

