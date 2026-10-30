param(
    [string]$BuildDirectory = "$PSScriptRoot/../build/Desktop_Qt_6_8_3_MSVC2022_64bit-Release-futurewings",
    [string]$OutputDirectory = 'D:/futurewing_installers',
    [string]$CMake = 'C:/Qt/Tools/CMake_64/bin/cmake.exe',
    [string]$VCRedistPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$BuildDirectory = (Resolve-Path -LiteralPath $BuildDirectory).Path
$cache = Get-Content -LiteralPath "$BuildDirectory/CMakeCache.txt"
if ($cache -notcontains 'CMAKE_PROJECT_NAME:STATIC=FutureWings' -or
    $cache -notcontains 'CMAKE_BUILD_TYPE:STRING=Release') {
    throw 'Select the FutureWings Release build directory.'
}

# windeployqt locates the Microsoft redistributable through VCINSTALLDIR.
if (-not $env:VCINSTALLDIR) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $vsInstall = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($LASTEXITCODE -eq 0 -and $vsInstall) {
            $env:VCINSTALLDIR = Join-Path ($vsInstall | Select-Object -First 1) 'VC/'
        }
    }
}
if (-not $env:VCINSTALLDIR) {
    # A copied/offline VS installation may not be registered with vswhere.
    $compilerEntry = $cache | Where-Object { $_ -match '^CMAKE_CXX_COMPILER:[^=]+=' } | Select-Object -First 1
    if ($compilerEntry -and $compilerEntry -match '=([A-Za-z]:[/\\].*[/\\]VC)[/\\]Tools[/\\]') {
        $compilerVc = $Matches[1]
        if (Test-Path -LiteralPath "$compilerVc/Redist/MSVC") {
            $env:VCINSTALLDIR = "$compilerVc/"
        }
    }
}
if (-not $env:VCINSTALLDIR) {
    throw 'Visual Studio C++ tools were not found. Run from a Visual Studio developer environment.'
}

# The redistributable bundled with an old VS installation can be too old for Qt.
# Cache the official package; an explicit path supports offline packaging.
if (-not $VCRedistPath) {
    $prerequisites = Join-Path $BuildDirectory 'delivery-prerequisites'
    New-Item -ItemType Directory -Force -Path $prerequisites | Out-Null
    $VCRedistPath = Join-Path $prerequisites 'vc_redist.x64.exe'
    if (-not (Test-Path -LiteralPath $VCRedistPath)) {
        $download = "$VCRedistPath.download"
        Invoke-WebRequest -Uri 'https://aka.ms/vc14/vc_redist.x64.exe' -OutFile $download -UseBasicParsing
        Move-Item -LiteralPath $download -Destination $VCRedistPath -Force
    }
}
$VCRedistPath = (Resolve-Path -LiteralPath $VCRedistPath).Path
$signature = Get-AuthenticodeSignature -LiteralPath $VCRedistPath
$runtimeInfo = (Get-Item -LiteralPath $VCRedistPath).VersionInfo
$runtimeVersion = [version]$runtimeInfo.FileVersion
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation' -or
    $runtimeInfo.OriginalFilename -ine 'VC_redist.x64.exe' -or $runtimeVersion -lt [version]'14.44.0.0') {
    throw 'Use a valid Microsoft-signed x64 VC++ redistributable version 14.44 or later.'
}
$env:QGC_VC_REDIST = $VCRedistPath

& $CMake --build $BuildDirectory --config Release --target all
if ($LASTEXITCODE -ne 0) { throw 'Release build failed; installer was not copied.' }

# Use a new directory every time; never collect files from an old deployment.
$stage = Join-Path $BuildDirectory ('delivery-stage-' + [guid]::NewGuid().ToString('N'))
& $CMake --install $BuildDirectory --config Release --prefix $stage
if ($LASTEXITCODE -ne 0) { throw 'Deployment or NSIS failed; installer was not copied.' }

$releaseExe = Join-Path $BuildDirectory 'Release/FutureWings.exe'
$deployedExe = Join-Path $stage 'bin/FutureWings.exe'
if ((Get-FileHash -LiteralPath $releaseExe).Hash -ne (Get-FileHash -LiteralPath $deployedExe).Hash) {
    throw 'Deployed executable does not match the Release build.'
}
$installer = Join-Path $BuildDirectory 'FutureWings-installer.exe'
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$destination = Join-Path $OutputDirectory 'FutureWings-installer.exe'
Copy-Item -LiteralPath $installer -Destination $destination -Force
if ((Get-FileHash -LiteralPath $installer).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
    throw 'Installer copy verification failed.'
}
$manifest = [ordered]@{
    createdAt = (Get-Date).ToString('o')
    configuration = 'Release'
    buildDirectory = $BuildDirectory
    stagingDirectory = $stage
    installerSHA256 = (Get-FileHash -LiteralPath $destination).Hash
    executableSHA256 = (Get-FileHash -LiteralPath $deployedExe).Hash
    runtimeVersion = $runtimeVersion.ToString()
    runtimeSHA256 = (Get-FileHash -LiteralPath $VCRedistPath).Hash
    functionalAcceptance = 'NOT VERIFIED: installation, maps, instruments, UDP, serial, telemetry, clean PC'
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath "$destination.manifest.json" -Encoding UTF8
Write-Output "Verified installer: $destination"
