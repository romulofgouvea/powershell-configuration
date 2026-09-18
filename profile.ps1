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
#
# O proprio Terminal-Icons.psm1 le e reescreve esses mesmos arquivos
# (Export-Clixml -Force) ao importar. Com varias abas abrindo juntas,
# uma aba pode passar na verificacao abaixo e mesmo assim ler o cache
# no meio da escrita de outra aba (TOCTOU), causando "Import-Clixml:
# Root element is missing." + "Index operation failed; the array index
# evaluated to null." mesmo com a limpeza feita aqui. Por isso o mutex:
# serializa a validacao + import entre processos concorrentes.
$tiCache = Join-Path $env:APPDATA 'powershell\Community\Terminal-Icons'
$tiMutex = New-Object System.Threading.Mutex($false, 'Global\PowerShellProfile-TerminalIconsCache')
$tiLocked = $tiMutex.WaitOne(15000)
try {
    if (Test-Path $tiCache) {
        Get-ChildItem $tiCache -Filter *.xml -ErrorAction SilentlyContinue | ForEach-Object {
            try { [void](Import-Clixml -LiteralPath $_.FullName -ErrorAction Stop) }
            catch { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
        }
    }
    Import-Module Terminal-Icons
}
finally {
    if ($tiLocked) { $tiMutex.ReleaseMutex() }
    $tiMutex.Dispose()
}

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
