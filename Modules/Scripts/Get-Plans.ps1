<#
.SYNOPSIS
Lists all plans in the .claude/plans directory and begins an interactive session to
pick a specific plan and then choose to resume or edit that plan.
#>

Begin
{
    function GetPlanItems
    {
        param([System.IO.FileInfo[]]$Files)

        foreach ($f in $Files)
        {
            $firstLine = Get-Content $f.FullName -TotalCount 5 |
                Where-Object { $_.Trim() -ne "" } |
                Select-Object -First 1

            $title = ($firstLine -replace '^#+\s*', '').Trim()

            [PSCustomObject]@{
                Title    = $title
                FileName = $f.Name
                FullPath = $f.FullName
                Id       = $f.BaseName
                Date     = $f.LastWriteTime.ToString("MMM d, yyyy")
            }
        }
    }

    function RenderList
    {
        param(
            [array]$Items,
            [int]$SelectedIndex,
            [int]$ViewStart,
            [int]$ViewSize,
            [int]$StartRow
        )

        $width = [Console]::WindowWidth

        for ($vi = 0; $vi -lt $ViewSize; $vi++)
        {
            $i = $ViewStart + $vi
            [Console]::SetCursorPosition(0, $StartRow + $vi)

            if ($i -ge $Items.Count)
            {
                Write-Host (' ' * ($width - 1)) -NoNewline
                continue
            }

            $line = "  $($i + 1). $($Items[$i].Title)  |  $($Items[$i].FileName)  |  $($Items[$i].Date)"
            if ($line.Length -gt ($width - 1)) { $line = $line.Substring(0, $width - 1) }
            $pad = [Math]::Max(0, $width - $line.Length - 1)

            if ($i -eq $SelectedIndex)
            {
                Write-Host ($line + (' ' * $pad)) -ForegroundColor Black -BackgroundColor Cyan -NoNewline
            }
            else
            {
                Write-Host ($line + (' ' * $pad)) -ForegroundColor Gray -NoNewline
            }
        }

        [Console]::SetCursorPosition(0, $StartRow + $ViewSize)
        if ($Items.Count -gt $ViewSize)
        {
            $indicator = "  ($($SelectedIndex + 1) of $($Items.Count))"
            Write-Host $indicator.PadRight($width - 1) -ForegroundColor DarkGray -NoNewline
        }
        else
        {
            Write-Host (' ' * ($width - 1)) -NoNewline
        }
    }

    function NavigatePlans
    {
        param([array]$Items, [int]$ViewSize, [int]$StartRow)

        $selectedIndex = 0
        $viewStart     = 0

        RenderList $Items $selectedIndex $viewStart $ViewSize $StartRow

        while ($true)
        {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            switch ($key.VirtualKeyCode)
            {
                38 {  # Up arrow
                    if ($selectedIndex -gt 0)
                    {
                        $selectedIndex--
                        if ($selectedIndex -lt $viewStart) { $viewStart = $selectedIndex }
                        RenderList $Items $selectedIndex $viewStart $ViewSize $StartRow
                    }
                }
                40 {  # Down arrow
                    if ($selectedIndex -lt ($Items.Count - 1))
                    {
                        $selectedIndex++
                        if ($selectedIndex -ge ($viewStart + $ViewSize)) { $viewStart = $selectedIndex - $ViewSize + 1 }
                        RenderList $Items $selectedIndex $viewStart $ViewSize $StartRow
                    }
                }
                13 {  # Enter
                    return $Items[$selectedIndex]
                }
                { $_ -in 81, 113 } {  # Q / q
                    return $null
                }
                27 {  # Esc
                    return $null
                }
            }
        }
    }

    function GetSessionId
    {
        param([string]$Slug)

        $projectsDir = Join-Path $env:USERPROFILE ".claude\projects"
        $pattern     = [regex]::Escape("""slug"":""$Slug""")

        $match = Get-ChildItem $projectsDir -Filter "*.jsonl" -Recurse |
            Select-String -Pattern $pattern -List |
            Select-Object -First 1

        if ($match)
        {
            return [System.IO.Path]::GetFileNameWithoutExtension($match.Path)
        }
        return $null
    }

    function ShowActionPrompt
    {
        param([PSCustomObject]$Selected, [int]$ActionRow)

        [Console]::SetCursorPosition(0, $ActionRow)
        Write-Host ""
        Write-Host "  $($Selected.Title)" -ForegroundColor Cyan
        Write-Host "  [R] Resume   [E] Edit   [Esc] Cancel" -ForegroundColor DarkGray
        Write-Host ""

        while ($true)
        {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            switch ($key.VirtualKeyCode)
            {
                82 {  # R / r — Resume
                    $sessionId = GetSessionId $Selected.Id
                    if (-not $sessionId) { $sessionId = $Selected.Id }
                    [Console]::CursorVisible = $true
                    Write-Host "  Resuming: $sessionId" -ForegroundColor Green
                    Write-Host ""
                    $Host.UI.RawUI.FlushInputBuffer()
                    & claude --resume $sessionId
                    return
                }
                69 {  # E / e — Edit
                    [Console]::CursorVisible = $true
                    Write-Host "  Opening: $($Selected.FullPath)" -ForegroundColor Green
                    Write-Host ""
                    Invoke-Item $Selected.FullPath
                    return
                }
                27 {  # Esc — Cancel
                    Write-Host ""
                    return
                }
            }
        }
    }

    # ── Validate and load ───────────────────────────────────────────────────
    $plansDir = Join-Path $env:USERPROFILE ".claude\plans"

    if (-not (Test-Path $plansDir))
    {
        Write-Host "Plans directory not found: $plansDir" -ForegroundColor Red
        exit
    }

    $files = Get-ChildItem -Path $plansDir -Filter "*.md" | Sort-Object LastWriteTime -Descending
    if ($files.Count -eq 0)
    {
        Write-Host "No plans found." -ForegroundColor Yellow
        exit
    }

    $items = @(GetPlanItems $files)
}

Process
{
    [Console]::CursorVisible = $false

    try
    {
        Clear-Host
        [Console]::SetCursorPosition(0, 0)
        Write-Host ""
        Write-Host "  Plans  (arrow keys navigate · Enter to select · Q to quit)" -ForegroundColor DarkGray
        Write-Host ""

        $startRow     = [Console]::CursorTop
        $reservedRows = 5
        $viewSize     = [Math]::Min($items.Count, [Math]::Max(1, [Console]::WindowHeight - $startRow - $reservedRows))

        $selected = NavigatePlans $items $viewSize $startRow

        if ($null -eq $selected)
        {
            [Console]::SetCursorPosition(0, $startRow + $viewSize + 1)
            Write-Host ""
            return
        }

        ShowActionPrompt $selected ($startRow + $viewSize + 1)
    }
    finally
    {
        [Console]::CursorVisible = $true
    }
}
