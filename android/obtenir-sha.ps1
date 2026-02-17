# Script pour obtenir les SHA-1 et SHA-256 du keystore
# Usage: .\obtenir-sha.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Obtenir les SHA-1 et SHA-256" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "upload-keystore.jks"
$alias = "upload"

# Vérifier si le keystore existe
if (-not (Test-Path $keystorePath)) {
    Write-Host "ERREUR: Le keystore n'existe pas: $keystorePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Le keystore doit être dans le dossier android/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Keystore trouvé: $keystorePath" -ForegroundColor Green
Write-Host ""

# Trouver keytool
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

Write-Host "Demande du mot de passe du keystore..." -ForegroundColor Yellow
$securePassword = Read-Host "Entrez le mot de passe du keystore" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

Write-Host ""
Write-Host "Récupération des empreintes SHA..." -ForegroundColor Green
Write-Host ""

try {
    $command = "& '$keytoolPath' -list -v -keystore `"$keystorePath`" -alias `"$alias`" -storepass `"$password`""
    $output = Invoke-Expression $command 2>&1 | Out-String
    
    Write-Host $output -ForegroundColor Gray
    Write-Host ""
    
    # Extraire SHA-1
    if ($output -match "SHA1:\s+([A-F0-9:]+)") {
        $sha1 = $matches[1]
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  SHA-1 (Copiez ceci) :" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host $sha1 -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Extraire SHA-256
    if ($output -match "SHA256:\s+([A-F0-9:]+)") {
        $sha256 = $matches[1]
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  SHA-256 (Copiez ceci) :" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host $sha256 -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Instructions:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Copiez les SHA-1 et SHA-256 ci-dessus" -ForegroundColor Yellow
    Write-Host "2. Allez sur Firebase Console: https://console.firebase.google.com/" -ForegroundColor Yellow
    Write-Host "3. Sélectionnez votre projet: fama-7db84" -ForegroundColor Yellow
    Write-Host "4. Project Settings (⚙️) > Your apps > App Android" -ForegroundColor Yellow
    Write-Host "5. Cliquez sur 'Add fingerprint'" -ForegroundColor Yellow
    Write-Host "6. Ajoutez SHA-1 et SHA-256 (un par un)" -ForegroundColor Yellow
    Write-Host "7. Cliquez sur Save" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "ERREUR lors de la récupération des SHA:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Vérifiez que:" -ForegroundColor Yellow
    Write-Host "- Le mot de passe est correct" -ForegroundColor Yellow
    Write-Host "- Le keystore existe et est valide" -ForegroundColor Yellow
    exit 1
}

