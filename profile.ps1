# =====================================================================
#  PowerShell 7 profile
#  Este arquivo fica no repositorio e e carregado pelo $PROFILE.
#  Para atualizar: git pull nesta pasta.
# =====================================================================

# So configura recursos interativos quando ha um terminal de verdade
$IsInteractive = [Environment]::UserInteractive -and -not [Console]::IsOutputRedirected

# Limpando console
if ($IsInteractive) { try { Clear-Host } catch {} }

# Raiz do repositorio (pasta onde este arquivo esta)
$ROOT = $PSScriptRoot

# ---------------------------------------------------------------------
# Modulos
# ---------------------------------------------------------------------
foreach ($m in 'posh-git', 'PSReadLine', 'Terminal-Icons') {
    if (Get-Module -ListAvailable -Name $m) {
        Import-Module $m -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------
# PSReadLine - autocomplete e atalhos
# ---------------------------------------------------------------------
if ((Get-Module PSReadLine) -and $IsInteractive) {
    try {
        Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
        Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

        Set-PSReadLineOption -ShowToolTips
        Set-PSReadLineOption -HistoryNoDuplicates
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
        Set-PSReadLineOption -EditMode Windows
    } catch {}
}

# ---------------------------------------------------------------------
# oh-my-posh (prompt) - opcional, so ativa se estiver instalado
# ---------------------------------------------------------------------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
}

# ---------------------------------------------------------------------
# ls colorido (PowerLS)
# ---------------------------------------------------------------------
$powerLs = Join-Path $ROOT 'Scripts\powerls.psm1'
if (Test-Path $powerLs) {
    Import-Module $powerLs -Force
    Set-Alias -Name ls -Value PowerLS -Option AllScope
}

# ---------------------------------------------------------------------
# Aliases e funcoes uteis
# ---------------------------------------------------------------------
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function gs { git status }
function gp { git pull }
function which ($cmd) { (Get-Command $cmd -ErrorAction SilentlyContinue).Source }

# ---------------------------------------------------------------------
# Diretorio inicial
# ---------------------------------------------------------------------
if (Test-Path 'D:\workspace') {
    Set-Location 'D:\workspace'
}
