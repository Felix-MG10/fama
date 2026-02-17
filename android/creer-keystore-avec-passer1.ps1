# Script pour creer le keystore avec le mot de passe Passer@1
# Usage: .\creer-keystore-avec-passer1.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Creation du Keystore avec Passer@1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "upload-keystore.jks"
$keyPropertiesPath = "key.properties"
$alias = "upload"
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

# Sauvegarder l'ancien keystore s'il existe
if (Test-Path $keystorePath) {
    Write-Host "Un keystore existe deja." -ForegroundColor Yellow
    $backupPath = "$keystorePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $keystorePath -Destination $backupPath
    Write-Host "Ancien keystore sauvegarde dans: $backupPath" -ForegroundColor Cyan
    Write-Host ""
    Remove-Item $keystorePath -Force
}

Write-Host "Creation du nouveau keystore avec le mot de passe: Passer@1" -ForegroundColor Green
Write-Host ""

# Creer le keystore avec le mot de passe non-interactif
# On utilise -storepass et -keypass pour eviter les questions interactives
try {
    Write-Host "Exécution de keytool..." -ForegroundColor Cyan
    
    # Commande pour créer le keystore avec toutes les informations nécessaires
    $dname = "CN=Felix OMBAGHO, OU=Dakarapps, O=Dakarapps, L=Dakar, ST=Dakar, C=sn"
    
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
    
    # Verifier que le keystore fonctionne avec le mot de passe
    Write-Host "Verification du keystore..." -ForegroundColor Cyan
    $testResult = & $keytoolPath -list -v -keystore $keystorePath -storepass $storePassword -alias $alias 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Verification reussie!" -ForegroundColor Green
    } else {
        Write-Host "ATTENTION: La verification a echoue. Le keystore pourrait avoir un probleme." -ForegroundColor Yellow
    }
    
    # Creer ou mettre a jour key.properties
    Write-Host ""
    Write-Host "Creation du fichier key.properties..." -ForegroundColor Cyan
    
    $propertiesContent = "storePassword=$storePassword`nkeyPassword=$keyPassword`nkeyAlias=$alias`nstoreFile=$keystorePath`n"
    
    $propertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline
    
    Write-Host ""
    Write-Host "Fichier key.properties cree avec succes!" -ForegroundColor Green
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
Write-Host "Le keystore a ete cree avec le mot de passe: Passer@1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vous pouvez maintenant reconstruire votre application:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  cd .." -ForegroundColor Gray
Write-Host "  flutter clean" -ForegroundColor Gray
Write-Host "  flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""

