# Script pour creer le keystore dans android/app/ avec les specifications exactes
# Usage: Executer depuis la racine du projet

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Creation du Keystore dans android/app/" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "android\app\my-release-key.jks"
$keyPropertiesPath = "android\key.properties"
$alias = "my-key-alias"
$storePassword = "Passer@1"
$keyPassword = "Passer@1"

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

# Supprimer l'ancien keystore s'il existe
if (Test-Path $keystorePath) {
    Write-Host "Un keystore existe deja a: $keystorePath" -ForegroundColor Yellow
    $backupPath = "$keystorePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $keystorePath -Destination $backupPath -Force
    Write-Host "Ancien keystore sauvegarde dans: $backupPath" -ForegroundColor Cyan
    Remove-Item $keystorePath -Force
    Write-Host ""
}

Write-Host "Creation du keystore avec les parametres suivants:" -ForegroundColor Green
Write-Host "  Chemin: $keystorePath" -ForegroundColor Gray
Write-Host "  Alias: $alias" -ForegroundColor Gray
Write-Host "  Mot de passe keystore: $storePassword" -ForegroundColor Gray
Write-Host "  Mot de passe cle: $keyPassword" -ForegroundColor Gray
Write-Host "  Nom: Felix OMBAGHO" -ForegroundColor Gray
Write-Host "  Organisation: DakarApps" -ForegroundColor Gray
Write-Host "  Localite: Dakar" -ForegroundColor Gray
Write-Host "  Province: Dakar" -ForegroundColor Gray
Write-Host "  Pays: SN" -ForegroundColor Gray
Write-Host ""

# Creer le keystore avec toutes les informations
$dname = "CN=Felix OMBAGHO, OU=DakarApps, O=DakarApps, L=Dakar, ST=Dakar, C=SN"

try {
    Write-Host "Execution de keytool..." -ForegroundColor Cyan
    
    & $keytoolPath -genkey -v `
        -keystore $keystorePath `
        -storetype JKS `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias $alias `
        -storepass $storePassword `
        -keypass $keyPassword `
        -dname $dname
    
    if (-not (Test-Path $keystorePath)) {
        Write-Host "ERREUR: Le keystore n'a pas ete cree." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Keystore cree avec succes!" -ForegroundColor Green
    Write-Host ""
    
    # Verifier que le keystore fonctionne
    Write-Host "Verification du keystore..." -ForegroundColor Cyan
    $testResult = & $keytoolPath -list -v -keystore $keystorePath -storepass $storePassword -alias $alias 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Verification reussie! Le keystore fonctionne correctement." -ForegroundColor Green
    } else {
        Write-Host "ATTENTION: La verification a echoue." -ForegroundColor Yellow
    }
    
    # Mettre a jour key.properties
    Write-Host ""
    Write-Host "Mise a jour de key.properties..." -ForegroundColor Cyan
    
    # Le chemin dans key.properties doit etre relatif depuis android/
    # Donc si le keystore est dans android/app/, on met app/my-release-key.jks
    $storeFileInProperties = "app/my-release-key.jks"
    
    $propertiesContent = "storePassword=$storePassword`nkeyPassword=$keyPassword`nkeyAlias=$alias`nstoreFile=$storeFileInProperties`n"
    
    $propertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
    
    Write-Host ""
    Write-Host "Fichier key.properties mis a jour avec succes!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Contenu de key.properties:" -ForegroundColor Cyan
    Get-Content $keyPropertiesPath
    
} catch {
    Write-Host "ERREUR lors de la creation du keystore:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Configuration terminee!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Le keystore a ete cree dans: $keystorePath" -ForegroundColor Cyan
Write-Host "Avec le mot de passe: $storePassword" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vous pouvez maintenant reconstruire votre application:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  flutter clean" -ForegroundColor Gray
Write-Host "  flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""

