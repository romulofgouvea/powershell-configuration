# =====================================================================
#  PowerLS - listagem de diretorio colorida estilo Unix
# =====================================================================

function PowerLS {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [string]$Path = ".",
        [switch]$All
    )

    if (-not (Test-Path $Path)) {
        Write-Host "PowerLS: caminho nao encontrado: $Path" -ForegroundColor Red
        return
    }

    $params = @{ Path = $Path; ErrorAction = 'SilentlyContinue' }
    if ($All) { $params.Force = $true }

    $items = Get-ChildItem @params | Sort-Object { -not $_.PSIsContainer }, Name
    if (-not $items) { return }

    $colors = @{
        Directory = 'Cyan'
        Executable = 'Green'
        Archive   = 'Magenta'
        Image     = 'Yellow'
        Code      = 'Blue'
        Hidden    = 'DarkGray'
        Default   = 'Gray'
    }

    $exeExt     = '.exe', '.bat', '.cmd', '.ps1', '.sh', '.msi'
    $archiveExt = '.zip', '.rar', '.7z', '.tar', '.gz', '.tgz'
    $imageExt   = '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.svg', '.ico', '.webp'
    $codeExt    = '.js', '.ts', '.jsx', '.tsx', '.py', '.cs', '.java', '.go', '.rb', '.php', '.c', '.cpp', '.h', '.json', '.yml', '.yaml', '.xml', '.html', '.css'

    $termWidth = try { $Host.UI.RawUI.WindowSize.Width } catch { 120 }
    $maxLen    = ($items | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
    $colWidth  = $maxLen + 3
    $perRow    = [Math]::Max(1, [Math]::Floor($termWidth / $colWidth))

    $i = 0
    foreach ($item in $items) {
        $ext = $item.Extension.ToLower()
        $color =
            if ($item.PSIsContainer) { $colors.Directory }
            elseif ($item.Attributes -band [IO.FileAttributes]::Hidden) { $colors.Hidden }
            elseif ($exeExt     -contains $ext) { $colors.Executable }
            elseif ($archiveExt -contains $ext) { $colors.Archive }
            elseif ($imageExt   -contains $ext) { $colors.Image }
            elseif ($codeExt    -contains $ext) { $colors.Code }
            else { $colors.Default }

        $name = $item.Name
        if ($item.PSIsContainer) { $name += '\' }
        Write-Host ($name.PadRight($colWidth)) -ForegroundColor $color -NoNewline

        $i++
        if ($i % $perRow -eq 0) { Write-Host "" }
    }
    if ($i % $perRow -ne 0) { Write-Host "" }
}

Export-ModuleMember -Function PowerLS
