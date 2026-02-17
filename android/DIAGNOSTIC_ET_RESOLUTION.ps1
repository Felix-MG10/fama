# Script de diagnostic et resolution complete du probleme de signature debug
# Usage: .\DIAGNOSTIC_ET_RESOLUTION.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC ET RESOLUTION" -ForegroundColor Cyan
Write-Host "  Signature en Mode Debug" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $projectRoot "android"

# Changer vers le repertoire android
Push-Location $androidDir

Write-Host "=== ETAPE 1: DIAGNOSTIC ===" -ForegroundColor Yellow
Write-Host ""

# 1. Verifier key.properties
Write-Host "1. Verification de key.properties..." -ForegroundColor Cyan
if (Test-Path "key.properties") {
    Write-Host "   ✓ Fichier existe" -ForegroundColor Green
    $keyProps = Get-Content "key.properties"
    $storeFile = ($keyProps | Where-Object { $_ -match "^storeFile=" }) -replace "storeFile=", ""
    $keyAlias = ($keyProps | Where-Object { $_ -match "^keyAlias=" }) -replace "keyAlias=", ""
    $storePassword = ($keyProps | Where-Object { $_ -match "^storePassword=" }) -replace "storePassword=", ""
    
    Write-Host "   - storeFile: $storeFile" -ForegroundColor Gray
    Write-Host "   - keyAlias: $keyAlias" -ForegroundColor Gray
    Write-Host "   - storePassword: $(if ($storePassword) { '***' } else { 'MANQUANT' })" -ForegroundColor Gray
} else {
    Write-Host "   ✗ Fichier MANQUANT!" -ForegroundColor Red
    Write-Host "   ERREUR: key.properties n'existe pas dans android/" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""

# 2. Verifier le keystore
Write-Host "2. Verification du keystore..." -ForegroundColor Cyan
$keystoreFullPath = Join-Path $androidDir $storeFile
if (Test-Path $keystoreFullPath) {
    Write-Host "   ✓ Keystore existe: $keystoreFullPath" -ForegroundColor Green
    $keystoreInfo = Get-Item $keystoreFullPath
    Write-Host "   - Taille: $($keystoreInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "   - Date: $($keystoreInfo.LastWriteTime)" -ForegroundColor Gray
    
    # Tester le mot de passe
    $keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($keytoolCmd) {
        $testResult = & $keytoolCmd.Source -list -keystore $keystoreFullPath -storepass $storePassword -alias $keyAlias 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✓ Mot de passe correct!" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Mot de passe INCORRECT!" -ForegroundColor Red
            Write-Host "   ERREUR: Le mot de passe dans key.properties ne correspond pas au keystore" -ForegroundColor Red
            Pop-Location
            exit 1
        }
    }
} else {
    Write-Host "   ✗ Keystore MANQUANT!" -ForegroundColor Red
    Write-Host "   Chemin recherche: $keystoreFullPath" -ForegroundColor Gray
    Write-Host "   ERREUR: Le keystore n'existe pas au chemin specifie dans key.properties" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""

# 3. Verifier build.gradle.kts
Write-Host "3. Verification de build.gradle.kts..." -ForegroundColor Cyan
$gradleFile = Join-Path $androidDir "app\build.gradle.kts"
if (Test-Path $gradleFile) {
    $gradleContent = Get-Content $gradleFile -Raw
    if ($gradleContent -match "rootProject\.file\(storeFile\)") {
        Write-Host "   ✓ Utilise rootProject.file() pour resoudre le chemin" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ ATTENTION: Ne semble pas utiliser rootProject.file()" -ForegroundColor Yellow
    }
    if ($gradleContent -match "signingConfig.*release") {
        Write-Host "   ✓ Configuration de signature release trouvee" -ForegroundColor Green
    }
} else {
    Write-Host "   ✗ Fichier MANQUANT!" -ForegroundColor Red
}

Write-Host ""

# 4. Verifier les anciens fichiers de build
Write-Host "4. Verification des fichiers de build existants..." -ForegroundColor Cyan
$buildOutputs = @(
    (Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"),
    (Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk")
)

foreach ($output in $buildOutputs) {
    if (Test-Path $output) {
        Write-Host "   ⚠ Fichier existant trouve: $(Split-Path $output -Leaf)" -ForegroundColor Yellow
        Write-Host "      Ce fichier pourrait etre signe en mode debug!" -ForegroundColor Yellow
    }
}

Write-Host ""

Write-Host "=== ETAPE 2: RESOLUTION ===" -ForegroundColor Yellow
Write-Host ""

$continue = Read-Host "Voulez-vous proceder au nettoyage et reconstruction? (oui/non)"
if ($continue -ne "oui" -and $continue -ne "o" -and $continue -ne "y" -and $continue -ne "yes") {
    Write-Host "Operation annulee." -ForegroundColor Yellow
    Pop-Location
    exit 0
}

# Nettoyage complet
Write-Host ""
Write-Host "1. Nettoyage complet..." -ForegroundColor Cyan
Push-Location $projectRoot

# Nettoyer Flutter
Write-Host "   - Nettoyage Flutter..." -ForegroundColor Gray
& flutter clean 2>&1 | Out-Null

# Nettoyer Gradle
Write-Host "   - Nettoyage Gradle..." -ForegroundColor Gray
if (Test-Path (Join-Path $androidDir ".gradle")) {
    Remove-Item -Recurse -Force (Join-Path $androidDir ".gradle") -ErrorAction SilentlyContinue
}
if (Test-Path (Join-Path $androidDir "app\build")) {
    Remove-Item -Recurse -Force (Join-Path $androidDir "app\build") -ErrorAction SilentlyContinue
}

Write-Host "   ✓ Nettoyage termine" -ForegroundColor Green
Write-Host ""

# Construction
Write-Host "2. Construction du bundle en mode RELEASE..." -ForegroundColor Cyan
Write-Host "   Cette etape peut prendre plusieurs minutes..." -ForegroundColor Gray
Write-Host ""

$buildResult = & flutter build appbundle --release 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "   ✓ Build reussi!" -ForegroundColor Green
    Write-Host ""
    
    # Verification de la signature
    Write-Host "3. Verification de la signature..." -ForegroundColor Cyan
    $aabPath = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
    
    if (Test-Path $aabPath) {
        $jarsignerCmd = Get-Command jarsigner -ErrorAction SilentlyContinue
        if ($jarsignerCmd) {
            $verifyResult = & $jarsignerCmd.Source -verify -verbose -certs $aabPath 2>&1
            
            if ($verifyResult -match "CN=Android Debug") {
                Write-Host "   ✗ ERREUR: L'application est toujours signee en mode DEBUG!" -ForegroundColor Red
                Write-Host "   La configuration n'a pas fonctionne correctement." -ForegroundColor Yellow
            } elseif ($verifyResult -match "CN=") {
                Write-Host "   ✓ SUCCES: L'application est signee en mode RELEASE!" -ForegroundColor Green
                $certMatch = [regex]::Match($verifyResult, "CN=([^,]+)")
                if ($certMatch.Success) {
                    Write-Host "   Certificate: $($certMatch.Groups[1].Value)" -ForegroundColor Gray
                }
            } else {
                Write-Host "   ⚠ Impossible de verifier la signature automatiquement" -ForegroundColor Yellow
                Write-Host "   Verifiez manuellement avec: jarsigner -verify -verbose -certs $aabPath" -ForegroundColor Gray
            }
        } else {
            Write-Host "   ⚠ jarsigner non trouve, verification manuelle necessaire" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "=== FICHIER PRET ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "Fichier AAB cree: $aabPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Vous pouvez maintenant uploader ce fichier sur Google Play Console." -ForegroundColor Yellow
        Write-Host "L'erreur de signature debug ne devrait plus apparaître!" -ForegroundColor Green
        }
    }
} else {
    Write-Host ""
    Write-Host "   ✗ ERREUR lors du build!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Sortie du build:" -ForegroundColor Yellow
    $buildResult | Select-Object -Last 30
    Pop-Location
    Pop-Location
    exit 1
}

Pop-Location
Pop-Location

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DIAGNOSTIC TERMINE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

