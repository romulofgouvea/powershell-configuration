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
# Terminal-Icons: remove caches de tema corrompidos antes de importar.
# Um .xml truncado (ex.: shutdown durante gravacao) faz o modulo lancar
#   "Import-Clixml: 'Element' is an invalid XmlNodeType"
#   "Index operation failed; the array index evaluated to null"
# na cada abertura do terminal. Os arquivos sao recriados no proximo load.
# ---------------------------------------------------------------------
$tiCache = Join-Path $env:APPDATA 'powershell\Community\Terminal-Icons'
if (Test-Path $tiCache) {
    Get-ChildItem $tiCache -Filter *.xml -ErrorAction SilentlyContinue | ForEach-Object {
        try { [void](Import-Clixml -LiteralPath $_.FullName -ErrorAction Stop) }
        catch { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }
}

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
# Prompt
# posh-git ja instala o prompt padrao ao ser importado:
#   ~\workspace\power-shell-profile [master +0 ~1 -0 !]
#
# oh-my-posh fica desativado de proposito (sobrescreve o posh-git).
# Para reativar: defina $env:USE_OH_MY_POSH = '1' e reabra o terminal.
# ---------------------------------------------------------------------
if ($env:USE_OH_MY_POSH -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    oh-my-posh init pwsh | Invoke-Expression
}
else {
    # -----------------------------------------------------------------
    # Limpa estado vazado do oh-my-posh.
    # Um terminal aberto antes de o oh-my-posh ser desativado - ou um
    # servico de longa duracao que herdou o ambiente (ex.: Herd/Herdr) -
    # deixa variaveis POSH_* e ate o prompt sobrescrito vazando para os
    # shells filhos. Sem isso o prompt padrao do posh-git nao aparece.
    # -----------------------------------------------------------------
    Get-ChildItem Env: |
        Where-Object { $_.Name -like 'POSH_*' -and $_.Name -notin 'POSH_PATH', 'POSH_THEMES_PATH' } |
        ForEach-Object { Remove-Item "Env:\$($_.Name)" -ErrorAction SilentlyContinue }

    # oh-my-posh chegou a ser carregado neste processo (dot-source repetido
    # numa sessao ja aberta): desfaz o prompt e os hooks e devolve o posh-git.
    if (Get-Command Set-PoshContext -ErrorAction SilentlyContinue) {
        foreach ($fn in 'Set-PoshContext', 'Enable-PoshTooltips',
                        'Enable-PoshTransientPrompt', 'Enable-PoshLineError') {
            if (Test-Path "Function:\$fn") {
                Remove-Item "Function:\$fn" -Force -ErrorAction SilentlyContinue
            }
        }
        Get-EventSubscriber -ErrorAction SilentlyContinue |
            Where-Object { "$($_.SourceIdentifier) $($_.Action.Command)" -match 'omp|PoshContext' } |
            Unregister-Event -Force -ErrorAction SilentlyContinue

        # Derruba o prompt do oh-my-posh e deixa o posh-git reinstalar o dele
        # (posh-git nao sobrescreve um prompt customizado ja existente).
        if (Get-Module posh-git) {
            Remove-Item Function:\prompt -Force -ErrorAction SilentlyContinue
            Import-Module posh-git -Force -ErrorAction SilentlyContinue 3>$null
        }
    }
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
