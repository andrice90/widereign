# Live preview of the installer UI (tui.ps1). Re-renders whenever tui.ps1 is saved.
#   powershell -ExecutionPolicy Bypass -File tools\preview.ps1 [-TuiPath <path to tui.ps1>] [-Title X] [-Tags a,b] [-Theme name] [-Step confirm]
# Keys: 1 confirm  2 prompt+message  3 waiting  4 progress  5 finale  T next theme  Q quit
param(
    [string]$TuiPath,   # default ..\kit\data\setup\tui.ps1. NOT $Tui: names are case-insensitive and tui.ps1 owns $TUI
    [string]$Title = 'WIDEREIGN',
    [string[]]$Tags = @('Co-op', '21x9', '>60fps', 'Thicc Margot'),
    [string]$Theme = 'nightreign',
    [string]$Step = 'confirm',
    [string]$PromptMessage = 'This mod needs Seamless Co-op downloaded from Nexus Mods',
    [string]$PromptLabel = 'OPEN NEXUS MODS'
)
$ErrorActionPreference = 'Stop'
if (-not $TuiPath) { $TuiPath = Join-Path $PSScriptRoot '..\kit\data\setup\tui.ps1' }   # not in param(): $PSScriptRoot can be empty there
$TuiPath = (Resolve-Path $TuiPath).Path
$steps = 'confirm', 'prompt', 'waiting', 'progress', 'finale'
$sampleLogs = @(@('Game: C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING NIGHTREIGN\Game', 'ok'), @('Installed to C:\Users\you\AppData\Local\mod', 'ok'),
                @('Your group plays version 1.1.3.', 'info'), @('Leave the zip in your Downloads folder. I will pick it up.', 'info'))

function Set-Step($s) {
    $TUI.Logs = New-Object System.Collections.ArrayList; $TUI.Prompt = $null; $TUI.Scene = 'main'; $TUI.Hint = ''; $TUI.Status = ''
    if ($s -ne 'confirm') { foreach ($l in $sampleLogs) { [void]$TUI.Logs.Add(@{ t = $l[0]; c = $TUI.Pal[$l[1]] }) } }
    switch ($s) {
        'confirm'  { $TUI.Pct = 0;  $TUI.Prompt = @{ label = "INSTALL $Title?"; key = '[enter]' }; $TUI.Hint = '[Esc] cancel' }
        'prompt'   { $TUI.Pct = 40; $TUI.Prompt = @{ label = $PromptLabel; msg = $PromptMessage; key = '[enter]' } }
        'waiting'  { $TUI.Pct = 40; $TUI.Status = 'Waiting for the download  |   126s'; $TUI.Hint = '[S] skip      [P] type a path' }
        'progress' { $TUI.Pct = 65; $TUI.Status = 'Copying files' }
        'finale'   { $TUI.Pct = 100; $TUI.Scene = 'finale'; $TUI.Features = $Tags; $TUI.FeatShown = $Tags.Count
                     $TUI.Prompt = @{ label = "PLAY $Title"; key = '[enter]' }; $TUI.Hint = 'starts the game      [Esc] close' }
    }
}

$stamp = [DateTime]::MinValue; $err = $null; $e = [char]27
$pulse = [Diagnostics.Stopwatch]::StartNew()
try {
    while ($true) {
        $m = (Get-Item $TuiPath).LastWriteTimeUtc
        if ($m -ne $stamp) {
            $stamp = $m
            try {
                . $TuiPath                                        # (re)defines the TUI-* functions
                TUI-Init -Title $Title -Tags $Tags -Theme $Theme
                if (-not $TUI.Fancy) { throw 'terminal has no 24-bit colour / VT support' }
                Set-Step $Step; TUIx-DrawScene; TUIx-Render; $err = $null
            } catch { $err = $_.Exception.Message }
        }
        if ($err) { [Console]::Write("$e[0m$e[2J$e[H  preview: tui.ps1 failed:`n  $err`n`n  (fix and save; it reloads)"); Start-Sleep -Milliseconds 400; continue }
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true).KeyChar
            if ($k -eq 'q' -or $k -eq 'Q') { break }
            if ($k -eq 't' -or $k -eq 'T') {
                $names = @($TUI_THEMES.Keys | Sort-Object); $Theme = $names[([array]::IndexOf($names, $Theme) + 1) % $names.Count]
                TUI-SetTheme $Theme -NoDraw; TUIx-Layout; Set-Step $Step; TUIx-DrawScene
            }
            if ("$k" -match '^[1-5]$') { $Step = $steps[[int]"$k" - 1]; Set-Step $Step; TUIx-DrawScene }
        }
        if ($pulse.ElapsedMilliseconds -gt 480) { $pulse.Restart(); $TUI.Lit = -not $TUI.Lit; TUIx-DrawScene }
        TUIx-Render
        [Console]::Write("$e[$($TUI.H);1H$e[0m$e[38;2;120;110;150mpreview: $Step  theme: $Theme   [1-5] screens  [T] theme  [Q] quit$e[K")
        Start-Sleep -Milliseconds 120
    }
} finally { TUI-Leave }
