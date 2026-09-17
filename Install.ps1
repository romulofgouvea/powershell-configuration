<#
.SYNOPSIS
    Instalador unico do profile do PowerShell.

.DESCRIPTION
    Clone o repositorio e rode este arquivo. Mais nada.
      - se necessario, instala o PowerShell 7 e continua nele
      - libera execucao de scripts para o usuario atual
      - confia na PSGallery e instala os modulos (posh-git, PSReadLine, Terminal-Icons)
      - faz backup do seu $PROFILE atual e aponta ele para este repo

.EXAMPLE
    .\Install.ps1
#>
[CmdletBinding()]
param(
    [switch]$Force
)

# =====================================================================
# 0. Bootstrap: garante que estamos rodando no PowerShell 7 (pwsh)
# =====================================================================
if ($PSVersionTable.PSVersion.Major -lt 6) {
    Write-Host "==> Este script precisa do PowerShell 7." -ForegroundColor Cyan

    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) {
        Write-Host "    PowerShell 7 nao encontrado. Instalando via winget..." -ForegroundColor Yellow
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id Microsoft.PowerShell --source winget `
                --accept-package-agreements --accept-source-agreements
        } else {
            Write-Host "    winget nao esta disponivel." -ForegroundColor Red
            Write-Host "    Instale o PowerShell 7 manualmente: https://aka.ms/powershell" -ForegroundColor Red
            return
        }
        $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        if (-not $pwsh) {
            foreach ($p in "$env:ProgramFiles\PowerShell\7\pwsh.exe",
                           "$env:LOCALAPPDATA\Microsoft\powershell\pwsh.exe") {
                if (Test-Path $p) { $pwsh = $p; break }
            }
        }
        if (-not $pwsh) {
            Write-Host "    PowerShell 7 instalado. Feche este terminal, abra o 'PowerShell 7' e rode de novo." -ForegroundColor Yellow
            return
        }
    }

    Write-Host "    Continuando no PowerShell 7..." -ForegroundColor Green
    $fwd = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)
    if ($Force) { $fwd += '-Force' }
    & $pwsh @fwd
    return
}

$ErrorActionPreference = 'Stop'
$repoRoot   = $PSScriptRoot
$profileSrc = Join-Path $repoRoot 'profile.ps1'

function Write-Step  { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "    $m" -ForegroundColor Green }
function Write-Warn2 { param($m) Write-Host "    $m" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  Configure PowerShell 7" -ForegroundColor Magenta
Write-Host "  ----------------------" -ForegroundColor Magenta
Write-Host ""

# ---------------------------------------------------------------------
# 1. Politica de execucao
# ---------------------------------------------------------------------
Write-Step "Liberando execucao de scripts (CurrentUser = RemoteSigned)"
try {
    if ((Get-ExecutionPolicy -Scope CurrentUser) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    }
    Write-Ok "OK"
} catch {
    Write-Warn2 "Nao foi possivel alterar: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------
# 2. PSGallery / NuGet
# ---------------------------------------------------------------------
Write-Step "Preparando repositorio de modulos (PSGallery)"
try {
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    Write-Ok "OK"
} catch {
    Write-Warn2 "aviso: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------
# 3. Modulos
# ---------------------------------------------------------------------
foreach ($m in 'posh-git', 'PSReadLine', 'Terminal-Icons') {
    Write-Step "Modulo: $m"
    if ((Get-Module -ListAvailable -Name $m) -and -not $Force) {
        Write-Ok "ja instalado"
        continue
    }
    try {
        Install-Module -Name $m -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
        Write-Ok "instalado"
    } catch {
        Write-Warn2 "falhou: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------
# 4. $PROFILE aponta para este repo
# ---------------------------------------------------------------------
Write-Step "Configurando `$PROFILE"
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$loaderLine = ". `"$profileSrc`""

if (Test-Path $PROFILE) {
    $current = Get-Content $PROFILE -Raw
    if ($current -match [regex]::Escape($profileSrc)) {
        Write-Ok "ja aponta para o repo"
    } else {
        $backup = "$PROFILE.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item $PROFILE $backup
        Write-Warn2 "backup do profile atual: $backup"
        Add-Content -Path $PROFILE -Value "`n# Configure-PowerShell`n$loaderLine"
        Write-Ok "linha adicionada"
    }
} else {
    Set-Content -Path $PROFILE -Value "# Configure-PowerShell`n$loaderLine" -Encoding UTF8
    Write-Ok "profile criado"
}

# ---------------------------------------------------------------------
# Fim
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "  Pronto! Feche e abra o PowerShell 7." -ForegroundColor Green
Write-Host ""
