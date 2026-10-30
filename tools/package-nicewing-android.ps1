param(
    [string]$BuildDirectory = "$PSScriptRoot/../build/Qt_6_8_3_for_Android_arm64_v8a-Release-nicewing-android",
    [string]$OutputDirectory = 'D:/futurewinginstallers',
    [switch]$BuildUnsigned,
    [string]$CMake = 'C:/Qt/Tools/CMake_64/bin/cmake.exe',
    [string]$Jdk = 'C:/Program Files/Java/jdk-17.0.12'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$BuildDirectory = (Resolve-Path -LiteralPath $BuildDirectory).Path
$cache = Get-Content -LiteralPath "$BuildDirectory/CMakeCache.txt"
foreach ($entry in @('CMAKE_PROJECT_NAME:STATIC=NiceWing', 'CMAKE_BUILD_TYPE:STRING=Release', 'ANDROID_ABI:STRING=arm64-v8a', 'QGC_BRAND:STRING=nicewing')) {
    if ($cache -notcontains $entry) { throw "Wrong build configuration: expected $entry" }
}
$settingsPath = Join-Path $BuildDirectory 'android-NiceWing-deployment-settings.json'
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
if ($settings.'application-binary' -ne 'NiceWing') { throw 'Expected NiceWing deployment settings.' }
$sdk = $settings.sdk
$tools = Join-Path $sdk "build-tools/$($settings.sdkBuildToolsRevision)"
$readelf = Join-Path $settings.ndk 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe'
$env:JAVA_HOME = $Jdk
$env:PATH = "$Jdk/bin;C:/Qt/Tools/Ninja;$env:PATH"
$root = Split-Path $PSScriptRoot -Parent

if ($BuildUnsigned) {
    if ([int]$settings.'android-min-sdk-version' -lt 28) {
        & $CMake -S $root -B $BuildDirectory -DQGC_QT_ANDROID_MIN_SDK_VERSION=28
        if ($LASTEXITCODE -ne 0) { throw 'Android configuration failed.' }
    }
    & $CMake --build $BuildDirectory --config Release --target all --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'Android native build failed.' }
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $deployment = Join-Path $BuildDirectory ('android-delivery-' + [guid]::NewGuid().ToString('N'))
    $nativeDirectory = Join-Path $deployment 'libs/arm64-v8a'
    New-Item -ItemType Directory -Path $nativeDirectory -Force | Out-Null
    Copy-Item -LiteralPath "$BuildDirectory/Release/libNiceWing_arm64-v8a.so" -Destination $nativeDirectory
    $deployqt = Join-Path (Split-Path $settings.'qml-importscanner-binary' -Parent) 'androiddeployqt.exe'
    & $deployqt --input $settingsPath --output $deployment --android-platform android-35 --jdk $Jdk --gradle --release --no-gdbserver
    if ($LASTEXITCODE -ne 0) { throw 'androiddeployqt failed; nothing was published.' }
    $metadataPath = Join-Path $deployment 'build/outputs/apk/release/output-metadata.json'
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    if ($metadata.elements.Count -ne 1) { throw 'Expected exactly one arm64 APK.' }
    $apk = Join-Path (Split-Path $metadataPath -Parent) $metadata.elements[0].outputFile
    $filename = 'NiceWing-android-release-unsigned.apk'
} else {
    # Qt Creator runs this after its Build Android APK/signing step.
    # Never search other directories or silently select an older signed file.
    $deployment = Join-Path $BuildDirectory 'android-build-NiceWing'
    $apk = Join-Path $deployment 'build/outputs/apk/release/android-build-NiceWing-release-signed.apk'
    $filename = 'NiceWing-android-release-signed.apk'
    $pending = & 'C:/Qt/Tools/Ninja/ninja.exe' -C $BuildDirectory -n 2>&1
    $pendingExit = $LASTEXITCODE
    # Qt's always-run binary-copy target is harmless; compilation, resources or
    # CMake regeneration pending here mean the APK cannot represent current code.
    $scheduled = @($pending | Where-Object { $_ -match '^\[\d+/\d+\]' })
    $outdated = @($scheduled | Where-Object { $_ -notmatch 'Copying NiceWing binary to apk folder' })
    if ($pendingExit -ne 0 -or $outdated.Count -gt 0) {
        throw 'Native build is not current. Rebuild NiceWing Release and its signed APK first.'
    }
}
if (-not (Test-Path -LiteralPath $apk)) { throw "Expected APK is missing: $apk" }
$gradleProperties = Get-Content -LiteralPath (Join-Path $deployment 'gradle.properties')
if ($gradleProperties -notcontains 'androidPackageName=com.futurewings.nicewing') {
    throw 'androiddeployqt parsed an incorrect package name. Regenerate the Android package.'
}
$badging = & "$tools/aapt.exe" dump badging $apk
if ($LASTEXITCODE -ne 0) { throw 'APK metadata could not be read.' }
$description = $badging -join "`n"
if ($description -notmatch "package: name='com.futurewings.nicewing'" -or
    $description -notmatch "application-label:'NiceWing'" -or
    $description -notmatch "native-code: 'arm64-v8a'" -or $description -match 'application-debuggable') {
    throw 'APK identity, ABI or Release status is incorrect.'
}
$minSdk = [int]([regex]::Match($description, "sdkVersion:'(\d+)'").Groups[1].Value)
$targetSdk = [int]([regex]::Match($description, "targetSdkVersion:'(\d+)'").Groups[1].Value)
$versionCode = [long]([regex]::Match($description, "versionCode='(\d+)'").Groups[1].Value)
$versionName = [regex]::Match($description, "versionName='([^']+)'").Groups[1].Value
if ($minSdk -lt 28 -or $targetSdk -ne [int]$settings.'android-target-sdk-version' -or
    $versionName -ne $settings.'android-version-name' -or $versionCode -ne [long]$settings.'android-version-code') {
    throw 'APK SDK/version does not match current CMake deployment settings.'
}
if (-not $BuildUnsigned) {
    $verification = & "$tools/apksigner.bat" verify --verbose --print-certs $apk 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    $cert = [regex]::Match(($verification -join "`n"), 'Signer #1 certificate SHA-256 digest: ([0-9a-fA-F]+)').Groups[1].Value.ToLowerInvariant()
    # Existing NiceWing APK delivered in D:\futurewinginstallers (2026-10-28).
    if ($cert -ne 'ae73aa7c471c04d61026a9299622e01efc93a8899a5b9637ce4a1fbb481a6308') {
        throw 'Signing certificate differs from the existing NiceWing release; upgrade compatibility is not established.'
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$audit = Join-Path ([IO.Path]::GetTempPath()) ('nicewing-apk-check-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $audit | Out-Null
$zip = [IO.Compression.ZipFile]::OpenRead($apk)
try {
    $entry = $zip.GetEntry('lib/arm64-v8a/libNiceWing_arm64-v8a.so')
    if (-not $entry) { throw 'APK is missing the NiceWing native library.' }
    $packagedSo = Join-Path $audit 'libNiceWing.so'
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $packagedSo)
    if (-not $zip.GetEntry('assets/android_rcc_bundle.rcc')) { throw 'APK is missing bundled Qt resources.' }
} finally { $zip.Dispose() }
$nativeSo = Join-Path $BuildDirectory 'Release/libNiceWing_arm64-v8a.so'
$nativeNotes = & $readelf -n $nativeSo
if ($LASTEXITCODE -ne 0) { throw 'Could not read native Release build ID.' }
$packagedNotes = & $readelf -n $packagedSo
if ($LASTEXITCODE -ne 0) { throw 'Could not read packaged build ID.' }
$nativeId = [regex]::Match(($nativeNotes -join "`n"), 'Build ID: ([0-9a-f]+)').Groups[1].Value
$packagedId = [regex]::Match(($packagedNotes -join "`n"), 'Build ID: ([0-9a-f]+)').Groups[1].Value
if (-not $nativeId -or $nativeId -ne $packagedId) { throw 'APK contains an older/different native application.' }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$dest = Join-Path $OutputDirectory $filename
$temporary = "$dest.$([guid]::NewGuid().ToString('N')).partial"
Copy-Item -LiteralPath $apk -Destination $temporary -Force
$hash = (Get-FileHash -LiteralPath $apk).Hash
if ((Get-FileHash -LiteralPath $temporary).Hash -ne $hash) { throw 'APK copy hash mismatch.' }
Move-Item -LiteralPath $temporary -Destination $dest -Force
[ordered]@{
    createdAt = (Get-Date).ToString('o')
    sourceApk = $apk
    sha256 = $hash
    applicationId = 'com.futurewings.nicewing'
    versionCode = $versionCode
    versionName = $versionName
    minSdk = $minSdk
    targetSdk = $targetSdk
    abi = 'arm64-v8a'
    nativeBuildId = $nativeId
    signed = (-not $BuildUnsigned.IsPresent)
    certificateSHA256 = $cert
    functionalAcceptance = 'NOT VERIFIED: device installation, upgrade, maps, instruments, UDP, USB serial, video'
} | ConvertTo-Json | Set-Content -LiteralPath "$dest.manifest.json" -Encoding UTF8
Write-Output "Verified APK: $dest"
