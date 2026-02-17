# Script pour obtenir SHA-1 et SHA-256 du keystore de production
# Usage: Executer depuis la racine du projet

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Obtention SHA-1 et SHA-256 du Keystore" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "android\app\my-release-key.jks"
$storePassword = "Passer@1"
$alias = "my-key-alias"

# Verifier que le keystore existe
if (-not (Test-Path $keystorePath)) {
    Write-Host "ERREUR: Le keystore n'existe pas a: $keystorePath" -ForegroundColor Red
    Write-Host "Assurez-vous d'avoir cree le keystore d'abord." -ForegroundColor Yellow
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
    Write-Host "Veuillez installer Java JDK et ajouter JAVA_HOME a votre PATH." -ForegroundColor Yellow
    exit 1
}

Write-Host "Keystore trouve: $keystorePath" -ForegroundColor Green
Write-Host "Alias: $alias" -ForegroundColor Gray
Write-Host ""

# Obtenir SHA-1
Write-Host "Obtention du SHA-1..." -ForegroundColor Cyan
$sha1Result = & $keytoolPath -list -v -keystore $keystorePath -storepass $storePassword -alias $alias 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR lors de la lecture du keystore!" -ForegroundColor Red
    Write-Host $sha1Result -ForegroundColor Red
    exit 1
}

# Extraire SHA-1
$sha1Match = $sha1Result | Select-String -Pattern "SHA1:\s+([A-F0-9:]+)" -AllMatches
$sha1 = $null
if ($sha1Match) {
    $sha1 = $sha1Match.Matches[0].Groups[1].Value.Trim()
}

# Extraire SHA-256
$sha256Match = $sha1Result | Select-String -Pattern "SHA256:\s+([A-F0-9:]+)" -AllMatches
$sha256 = $null
if ($sha256Match) {
    $sha256 = $sha256Match.Matches[0].Groups[1].Value.Trim()
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  RESULTATS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($sha1) {
    Write-Host "SHA-1:" -ForegroundColor Yellow
    Write-Host $sha1 -ForegroundColor White
    Write-Host ""
    # Copier dans le presse-papier
    $sha1 | Set-Clipboard
    Write-Host "(SHA-1 copie dans le presse-papier)" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "ATTENTION: SHA-1 non trouve!" -ForegroundColor Red
    Write-Host ""
}

if ($sha256) {
    Write-Host "SHA-256:" -ForegroundColor Yellow
    Write-Host $sha256 -ForegroundColor White
    Write-Host ""
    # Copier dans le presse-papier
    $sha256 | Set-Clipboard
    Write-Host "(SHA-256 copie dans le presse-papier)" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "ATTENTION: SHA-256 non trouve!" -ForegroundColor Red
    Write-Host ""
}

if ($sha1 -or $sha256) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  PROCHAINES ETAPES" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Allez sur Firebase Console:" -ForegroundColor Yellow
    Write-Host "   https://console.firebase.google.com/project/fama-7db84/settings/general" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Dans 'Your apps', selectionnez votre app Android" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "3. Cliquez sur 'Add fingerprint'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "4. Ajoutez les empreintes SHA-1 et SHA-256 ci-dessus" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "5. Cliquez sur 'Save'" -ForegroundColor Yellow
    Write-Host ""
}

