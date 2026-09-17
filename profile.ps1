# =====================================================================
#  PowerShell 7 profile
#  Este arquivo fica no repositorio e e carregado pelo $PROFILE.
#  Para atualizar: git pull nesta pasta.
# =====================================================================

# Limpando console
Clear-Host

$ROOT = $PSScriptRoot

# ---------------------------------------------------------------------
# Modulos
# ---------------------------------------------------------------------
Import-Module posh-git
Import-Module PSReadLine

# Terminal-Icons: remove caches de tema corrompidos antes de importar.
# Um .xml truncado (ex.: varias abas abrindo ao mesmo tempo, ou shutdown
# durante gravacao) faz o modulo lancar "Import-Clixml: 'Element' is an
# invalid XmlNodeType" a cada abertura do terminal. Os arquivos sao
# recriados sozinhos no proximo load.
$tiCache = Join-Path $env:APPDATA 'powershell\Community\Terminal-Icons'
if (Test-Path $tiCache) {
    Get-ChildItem $tiCache -Filter *.xml -ErrorAction SilentlyContinue | ForEach-Object {
        try { [void](Import-Clixml -LiteralPath $_.FullName -ErrorAction Stop) }
        catch { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }
}
Import-Module Terminal-Icons

# ---------------------------------------------------------------------
# PSReadLine - autocomplete e atalhos
# ---------------------------------------------------------------------
Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -PredictionSource History

# ---------------------------------------------------------------------
# ls colorido (PowerLS)
# ---------------------------------------------------------------------
Import-Module "$ROOT\Scripts\powerls.psm1"
Set-Alias -Name ls -Value PowerLS -Option AllScope

# ---------------------------------------------------------------------
# Aliases e funcoes uteis
# ---------------------------------------------------------------------
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function gs { git status }
function gp { git pull }
function which ($cmd) { (Get-Command $cmd -ErrorAction SilentlyContinue).Source }
