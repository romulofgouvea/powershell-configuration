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
# PSReadLine ja vem carregado numa sessao interativa; o import e no-op.
# posh-git (~500ms) e Terminal-Icons (~520ms) sao pesados: carregam
# depois, quando o shell fica ocioso (bloco diferido mais abaixo), para
# o primeiro prompt aparecer em <500ms.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
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
        Set-PSReadLineOption -EditMode Windows

        # ListView so funciona com janela >= 50x5. Ambientes como o Herd/Herdr
        # (https://herdr.dev) sobem o pwsh num console minusculo e o
        # 'Set-PSReadLineOption -PredictionViewStyle ListView' cospe um WARNING
        # a cada prompt. Usa InlineView quando a janela e pequena/desconhecida.
        $win = try { $Host.UI.RawUI.WindowSize } catch { $null }
        if ($win -and $win.Width -ge 50 -and $win.Height -ge 5) {
            Set-PSReadLineOption -PredictionViewStyle ListView
        } else {
            Set-PSReadLineOption -PredictionViewStyle InlineView
        }
    } catch {}
}

# ---------------------------------------------------------------------
# Prompt provisorio (sincrono e barato)
# posh-git so instala o prompt dele ao ser importado, e o import e caro.
# Ate o bloco diferido rodar, mostra so o caminho atual - o posh-git
# reinstala o prompt completo (com git) assim que carrega.
# ---------------------------------------------------------------------
function global:prompt {
    "PS $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($NestedPromptLevel + 1)) "
}

# ---------------------------------------------------------------------
# Carga diferida: posh-git + Terminal-Icons (juntos ~1s).
# Rodam quando o shell fica ocioso pela primeira vez, logo apos o
# primeiro prompt. Assim o terminal fica utilizavel na hora e os
# modulos pesados entram uma fracao de segundo depois.
#
# oh-my-posh fica desativado de proposito (sobrescreve o posh-git).
# Para reativar: defina $env:USE_OH_MY_POSH = '1' e reabra o terminal.
# ---------------------------------------------------------------------
if ($IsInteractive) {
    $null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -Action {
        # roda uma vez so
        Get-EventSubscriber -SourceIdentifier PowerShell.OnIdle -ErrorAction SilentlyContinue |
            Unregister-Event -ErrorAction SilentlyContinue

        # Terminal-Icons: remove caches de tema corrompidos antes de importar.
        # Um .xml truncado (ex.: shutdown durante gravacao) faz o modulo lancar
        #   "Import-Clixml: 'Element' is an invalid XmlNodeType"
        # a cada abertura do terminal. Os arquivos sao recriados no proximo load.
        $tiCache = Join-Path $env:APPDATA 'powershell\Community\Terminal-Icons'
        if (Test-Path $tiCache) {
            Get-ChildItem $tiCache -Filter *.xml -ErrorAction SilentlyContinue | ForEach-Object {
                try { [void](Import-Clixml -LiteralPath $_.FullName -ErrorAction Stop) }
                catch { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
            }
        }

        if (Get-Module -ListAvailable -Name Terminal-Icons) {
            Import-Module Terminal-Icons -Global -ErrorAction SilentlyContinue
        }

        if ($env:USE_OH_MY_POSH -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
            Remove-Item Function:\prompt -Force -ErrorAction SilentlyContinue
            oh-my-posh init pwsh | Invoke-Expression
        }
        else {
            # Limpa estado vazado do oh-my-posh (variaveis POSH_* e prompt
            # sobrescrito herdados de um shell/servico anterior).
            Get-ChildItem Env: |
                Where-Object { $_.Name -like 'POSH_*' -and $_.Name -notin 'POSH_PATH', 'POSH_THEMES_PATH' } |
                ForEach-Object { Remove-Item "Env:\$($_.Name)" -ErrorAction SilentlyContinue }

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
            }

            # Remove o prompt provisorio para o posh-git instalar o dele.
            Remove-Item Function:\prompt -Force -ErrorAction SilentlyContinue
            if (Get-Module -ListAvailable -Name posh-git) {
                Import-Module posh-git -Global -Force -ErrorAction SilentlyContinue 3>$null
            }
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
