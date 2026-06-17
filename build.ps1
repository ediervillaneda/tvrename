param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug",

    [switch]$Run,
    [switch]$Clean,
    [switch]$Installer,
    [switch]$Help,

    # Version para el instalador, ej: "5.0.9" o "5.0.9-rc.1"
    # Si se omite, se lee desde AssemblyInfo.cs
    [string]$Version
)

if ($Help) {
    Write-Host @"
USO
  .\build.ps1 [opciones]

OPCIONES
  -Config <Debug|Release>   Configuracion de build (default: Debug)
  -Clean                    Ejecuta dotnet clean antes de build
  -Run                      Lanza TVRename.exe tras compilar
  -Installer                Genera el instalador NSIS (fuerza Release)
  -Version <semver>         Version para el instalador, ej: 5.0.9 o 5.0.9-rc.1
                            Si se omite, se lee desde AssemblyInfo.cs
  -Help                     Muestra esta ayuda

EJEMPLOS
  .\build.ps1                           Build Debug
  .\build.ps1 -Config Release           Build Release
  .\build.ps1 -Run                      Build Debug + lanzar app
  .\build.ps1 -Config Release -Clean    Build Release con clean previo
  .\build.ps1 -Installer                Build Release + instalador NSIS
  .\build.ps1 -Installer -Version 5.1.0 Instalador con version explicita

OUTPUT
  Debug:   TVRename\bin\x64\Debug\net8.0-windows\TVRename.exe
  Release: TVRename\bin\x64\Release\net8.0-windows\TVRename.exe
  NSIS:    TVRename-<version>.exe

REQUISITO (solo -Installer)
  NSIS instalado en: ${env:ProgramFiles(x86)}\NSIS\
  Descarga: https://nsis.sourceforge.io/Download
"@
    exit 0
}

$dotnet  = "C:\Program Files\dotnet\dotnet.exe"
$makensis = "${env:ProgramFiles(x86)}\NSIS\makensis.exe"
$sln     = "TVRename.sln"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Get-Version {
    # 1. Git tag exacto en el commit actual
    $tag = git describe --tags --exact-match HEAD 2>$null
    if ($tag) { return $tag.TrimStart('v') }

    # 2. Tag más reciente (puede ser commits atrás)
    $tag = git describe --tags --abbrev=0 2>$null
    if ($tag) { return $tag.TrimStart('v') }

    # 3. Fallback: AssemblyInfo.cs
    $info = Get-Content "TVRename\Properties\AssemblyInfo.cs" | Select-String 'AssemblyFileVersion\("([^"]+)"\)'
    if ($info) { return $info.Matches[0].Groups[1].Value }

    return "0.0.0"
}

function Get-FriendlyVersion([string]$tag) {
    $core = ($tag -split '-')[0]
    if ($tag -like '*-*') {
        $suffix = ($tag -split '-', 2)[1]
        $suffix = (Get-Culture).TextInfo.ToTitleCase($suffix.ToLower())
        $suffix = $suffix -replace '([a-zA-Z]+)(\d+)', '$1 $2'
        return "$core $suffix"
    }
    return $core
}

# ── Clean ─────────────────────────────────────────────────────────────────────

if ($Clean) {
    Write-Host "Cleaning..." -ForegroundColor Yellow
    & $dotnet clean $sln -c $Config --nologo
}

# ── Build ─────────────────────────────────────────────────────────────────────

if ($Installer -and $Config -ne "Release") {
    Write-Host "Installer requiere Release. Cambiando config..." -ForegroundColor Yellow
    $Config = "Release"
}

Write-Host "Building [$Config]..." -ForegroundColor Cyan
& $dotnet build $sln -c $Config --nologo
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$exePath = "TVRename\bin\x64\$Config\net8.0-windows\TVRename.exe"
Write-Host "Output: $exePath" -ForegroundColor Green

# ── Installer ─────────────────────────────────────────────────────────────────

if ($Installer) {
    if (-not (Test-Path $makensis)) {
        Write-Error "NSIS no encontrado en '$makensis'. Instálalo desde https://nsis.sourceforge.io/Download"
        exit 1
    }

    $tag      = if ($Version) { $Version } else { Get-Version }
    $friendly = Get-FriendlyVersion $tag

    Write-Host "Construyendo instalador v$tag ($friendly)..." -ForegroundColor Cyan

    & $makensis /WX /DVERSION="$friendly" /DTAG="$tag" Installer.nsi
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $installer = "TVRename-$tag.exe"
    if (Test-Path $installer) {
        Write-Host "Instalador: $installer" -ForegroundColor Green
    }
}

# ── Run ───────────────────────────────────────────────────────────────────────

if ($Run) {
    Write-Host "Launching..." -ForegroundColor Cyan
    & ".\$exePath"
}
