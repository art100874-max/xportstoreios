$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$gradleRoot = Join-Path $repoRoot "build\xportstore\android\gradle"
$overlayRoot = Join-Path $repoRoot "android-overlay"
$briefcaseSdk = Join-Path $env:LOCALAPPDATA "BeeWare\briefcase\Cache\tools\android_sdk"
$briefcaseJava = Join-Path $env:LOCALAPPDATA "BeeWare\briefcase\Cache\tools\java17"
$artifactDir = Join-Path $repoRoot "artifacts"
$artifactPath = Join-Path $artifactDir "XPortStore-Android-1.1.0-debug.apk"

Push-Location $repoRoot
try {
    if (-not (Test-Path (Join-Path $gradleRoot "gradlew.bat"))) {
        python -m briefcase create android --no-input
        if ($LASTEXITCODE -ne 0) { throw "Briefcase Android create failed." }
    }

    python -m briefcase update android --no-input
    if ($LASTEXITCODE -ne 0) { throw "Briefcase Android update failed." }

    Copy-Item -LiteralPath (Join-Path $overlayRoot "app\src\main\AndroidManifest.xml") -Destination (Join-Path $gradleRoot "app\src\main\AndroidManifest.xml") -Force

    $activityDestination = Join-Path $gradleRoot "app\src\main\java\ru\xportstore\xportstore\XportMainActivity.java"
    New-Item -ItemType Directory -Path (Split-Path $activityDestination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $overlayRoot "app\src\main\java\ru\xportstore\xportstore\XportMainActivity.java") -Destination $activityDestination -Force

    $appGradlePath = Join-Path $gradleRoot "app\build.gradle"
    $appGradle = Get-Content -LiteralPath $appGradlePath -Raw
    $appGradle = $appGradle -replace '(?m)^(\s*)versionCode\s+\d+\s*$', '${1}versionCode 1001000'
    $appGradle = $appGradle -replace '(?m)^(\s*)versionName\s+"[^"]+"\s*$', '${1}versionName "1.1.0"'
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($appGradlePath, $appGradle, $utf8NoBom)

    if (-not (Test-Path $briefcaseSdk)) { throw "Briefcase Android SDK is missing: $briefcaseSdk" }
    if (-not (Test-Path (Join-Path $briefcaseJava "bin\java.exe"))) { throw "Briefcase Java 17 is missing: $briefcaseJava" }

    $env:ANDROID_HOME = $briefcaseSdk
    $env:ANDROID_SDK_ROOT = $briefcaseSdk
    $env:JAVA_HOME = $briefcaseJava

    $localProperties = "sdk.dir=" + ($briefcaseSdk -replace "\\", "\\\\")
    [System.IO.File]::WriteAllText((Join-Path $gradleRoot "local.properties"), $localProperties, $utf8NoBom)

    $gradlePropertiesPath = Join-Path $gradleRoot "gradle.properties"
    $gradleProperties = Get-Content -LiteralPath $gradlePropertiesPath -Raw
    if ($gradleProperties -notmatch '(?m)^android\.overridePathCheck=true$') {
        $gradleProperties = $gradleProperties.TrimEnd() + "`r`nandroid.overridePathCheck=true`r`n"
        [System.IO.File]::WriteAllText($gradlePropertiesPath, $gradleProperties, $utf8NoBom)
    }

    Push-Location $gradleRoot
    try {
        & .\gradlew.bat clean assembleDebug
        if ($LASTEXITCODE -ne 0) { throw "Gradle Android build failed." }
    } finally {
        Pop-Location
    }

    $builtApk = Join-Path $gradleRoot "app\build\outputs\apk\debug\app-debug.apk"
    if (-not (Test-Path $builtApk)) { throw "Built APK was not found: $builtApk" }

    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
    Copy-Item -LiteralPath $builtApk -Destination $artifactPath -Force
    Write-Output $artifactPath
} finally {
    Pop-Location
}
