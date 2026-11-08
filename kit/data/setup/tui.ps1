# tui.ps1 - full-window installer UI for Windows PowerShell 5.1+ (Windows Terminal / Win10+ console).
#
#   . "$PSScriptRoot\tui.ps1"
#   TUI-Init -Title 'MYMOD' -Tags 'Fast','Pretty' -Theme 'nightreign'
#   if ((TUI-Prompt -Label 'INSTALL MYMOD?' -Hint '[Esc] cancel') -eq 'Escape') { TUI-Leave; exit 0 }
#   TUI-Status 'Copying files'; TUI-Log 'Copied 3 files' 'ok'; TUI-Progress 50
#   $play = TUI-Finale -Features 'Fast','Pretty' -Label 'PLAY MYMOD'
#   TUI-Leave
#
# Layout: big gradient block-letter title + shadow, tag line, scrolling log, a translucent panel in the lower middle
# (status + %, or a prompt: message / ACTION / [enter]), key hints bottom-left. The background fills left to right
# with the theme gradient as progress goes up. Falls back to plain coloured lines when the terminal can't do 24-bit
# colour, output is redirected, or -Plain is passed.
#
# Everything lives in $script:TUI and functions named TUI-* (public) / TUIx-* (internal). Nothing else is reserved,
# so host scripts can use any variable names (PowerShell names are case-insensitive: $c and $C are the same variable).

$script:TUI = @{ E = [string][char]27; Fancy = $false; InAlt = $false; Demo = $false; Plain = $true }

# ---------------------------------------------------------------- themes
# fill   : background gradient stops @(t, r, g, b), left (t=0) to right (t=1)
# night  : unfilled background rgb          logo  : title gradient stops (diagonal)     shadow: title shadow hex
# panel  : translucent panel tint rgb       panelAlpha / edgeAlpha: panel opacity, brightness of the fill's leading edge
# pal    : text colours (hex). action = prompt action text, lit = its pulse, key = '[enter]', sep = tag separators,
#          tags = colours cycled over tags / finale features
$script:TUI_THEMES = @{
    nightreign = @{   # storm navy -> indigo -> spectral violet, silver-stone title, antique gold actions
        fill = @(@(0.00, 14, 20, 48), @(0.35, 35, 42, 99), @(0.70, 72, 66, 160), @(1.00, 169, 168, 222))
        night = @(7, 10, 23); shadow = '05070F'; panel = @(201, 212, 242); panelAlpha = 0.16; edgeAlpha = 0.18
        logo = @(@(0.00, 238, 241, 250), @(0.50, 174, 180, 200), @(1.00, 127, 134, 163))
        pal = @{ text = 'E8EEFF'; ok = '9FE3C0'; warn = 'E3C27A'; info = 'A9B8E8'; err = 'E07A8F'; dim = '7A80A8'
                 action = 'E3C27A'; lit = 'FFF0C8'; key = 'A9B8E8'; sep = 'D8829E'; tags = @('7FB8FF', 'D8829E', 'E3C27A', '9C8CD9') }
    }
    neon = @{         # night violet -> electric purple -> lavender, lilac-to-magenta title, bright gold actions
        fill = @(@(0.00, 26, 6, 51), @(0.40, 75, 21, 144), @(0.75, 123, 47, 247), @(1.00, 196, 150, 255))
        night = @(11, 6, 20); shadow = '12051F'; panel = @(233, 213, 255); panelAlpha = 0.16; edgeAlpha = 0.18
        logo = @(@(0.00, 250, 240, 255), @(0.45, 216, 140, 255), @(1.00, 255, 60, 214))
        pal = @{ text = 'F5F0FF'; ok = '8CFFB0'; warn = 'FFD166'; info = 'CDB8FF'; err = 'FF6B8B'; dim = '8E7BB8'
                 action = 'FFD24D'; lit = 'FFF6CC'; key = 'CDB8FF'; sep = 'FF7AE6'; tags = @('7FE7FF', 'FF7AE6', 'FFD24D', 'B57BFF') }
    }
    ember = @{        # charcoal -> oxblood -> forge orange, bone-white to amber title
        fill = @(@(0.00, 22, 10, 8), @(0.40, 92, 24, 16), @(0.75, 178, 64, 22), @(1.00, 246, 166, 92))
        night = @(12, 8, 7); shadow = '070302'; panel = @(255, 214, 180); panelAlpha = 0.14; edgeAlpha = 0.18
        logo = @(@(0.00, 255, 244, 228), @(0.50, 255, 190, 120), @(1.00, 214, 98, 52))
        pal = @{ text = 'FFF1E6'; ok = 'B9E59A'; warn = 'FFC56B'; info = 'F2C9A8'; err = 'FF7A6B'; dim = '9C7A6A'
                 action = 'FFC56B'; lit = 'FFF0D0'; key = 'F2C9A8'; sep = 'FF8A5B'; tags = @('FFB35C', 'FF8A5B', 'F2D6A0', 'E07A5F') }
    }
    frost = @{        # deep teal -> glacier blue -> ice, white-to-cyan title
        fill = @(@(0.00, 6, 22, 30), @(0.40, 14, 62, 88), @(0.75, 40, 130, 170), @(1.00, 180, 230, 245))
        night = @(4, 12, 18); shadow = '02070A'; panel = @(200, 240, 255); panelAlpha = 0.14; edgeAlpha = 0.18
        logo = @(@(0.00, 245, 252, 255), @(0.50, 170, 225, 245), @(1.00, 90, 170, 210))
        pal = @{ text = 'EAF8FF'; ok = '9FF0C8'; warn = 'FFE08A'; info = 'A8D8EA'; err = 'FF8A9A'; dim = '6E93A6'
                 action = 'FFE08A'; lit = 'FFF8D6'; key = 'A8D8EA'; sep = '7FDBFF'; tags = @('7FDBFF', 'B8F2E6', 'FFE08A', '9AB8FF') }
    }
}
function TUI-AddTheme([string]$Name, [hashtable]$Theme) { $script:TUI_THEMES[$Name] = $Theme }

# ---------------------------------------------------------------- block font (5 rows; '#' = filled)
$script:TUI_FONT = @{
    'A' = '.###.|#...#|#####|#...#|#...#'; 'B' = '####.|#...#|####.|#...#|####.'; 'C' = '.####|#....|#....|#....|.####'
    'D' = '####.|#...#|#...#|#...#|####.'; 'E' = '#####|#....|####.|#....|#####'; 'F' = '#####|#....|####.|#....|#....'
    'G' = '.####|#....|#..##|#...#|.###.'; 'H' = '#...#|#...#|#####|#...#|#...#'; 'I' = '###|.#.|.#.|.#.|###'
    'J' = '..###|...#.|...#.|#..#.|.##..'; 'K' = '#...#|#..#.|###..|#..#.|#...#'; 'L' = '#....|#....|#....|#....|#####'
    'M' = '#...#|##.##|#.#.#|#...#|#...#'; 'N' = '#...#|##..#|#.#.#|#..##|#...#'; 'O' = '.###.|#...#|#...#|#...#|.###.'
    'P' = '####.|#...#|####.|#....|#....'; 'Q' = '.###.|#...#|#.#.#|#..#.|.##.#'; 'R' = '####.|#...#|####.|#..#.|#...#'
    'S' = '.####|#....|.###.|....#|####.'; 'T' = '#####|..#..|..#..|..#..|..#..'; 'U' = '#...#|#...#|#...#|#...#|.###.'
    'V' = '#...#|#...#|#...#|.#.#.|..#..'; 'W' = '#...#|#...#|#.#.#|##.##|#...#'; 'X' = '#...#|.#.#.|..#..|.#.#.|#...#'
    'Y' = '#...#|.#.#.|..#..|..#..|..#..'; 'Z' = '#####|...#.|..#..|.#...|#####'
    '0' = '.###.|#..##|#.#.#|##..#|.###.'; '1' = '.#.|##.|.#.|.#.|###'; '2' = '####.|....#|.###.|#....|#####'
    '3' = '####.|....#|.###.|....#|####.'; '4' = '#...#|#...#|#####|....#|....#'; '5' = '#####|#....|####.|....#|####.'
    '6' = '.###.|#....|####.|#...#|.###.'; '7' = '#####|....#|...#.|..#..|..#..'; '8' = '.###.|#...#|.###.|#...#|.###.'
    '9' = '.###.|#...#|.####|....#|.###.'; ' ' = '...|...|...|...|...'; '-' = '...|...|###|...|...'
    '!' = '#|#|#|.|#'; '.' = '.|.|.|.|#'; '?' = '###.|...#|.##.|....|.#..'
}
function TUIx-Glyph($ch) { $g = $script:TUI_FONT[[string]$ch]; if (-not $g) { $g = $script:TUI_FONT[' '] }; $g.Split('|') }
function TUIx-LogoWidth($word) { $n = 0; foreach ($ch in $word.ToUpper().ToCharArray()) { $n += (TUIx-Glyph $ch)[0].Length + 1 }; $n }
function TUIx-LogoRows($word, $sx) {
    $rows = @('', '', '', '', '')
    foreach ($ch in $word.ToUpper().ToCharArray()) {
        $g = TUIx-Glyph $ch
        for ($r = 0; $r -lt 5; $r++) {
            foreach ($px in $g[$r].ToCharArray()) { $rows[$r] += $(if ($px -eq '#') { [string][char]0x2588 * $sx } else { ' ' * $sx }) }
            $rows[$r] += ' ' * $sx
        }
    }
    for ($r = 0; $r -lt 5; $r++) { $rows[$r] = $rows[$r].TrimEnd() }
    return ,$rows
}

# ---------------------------------------------------------------- colour helpers
function TUIx-Rgb($hex) { $h = $hex.TrimStart('#'); @([Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16)) }
function TUIx-Fg($hex) { $c = TUIx-Rgb $hex; "$($TUI.E)[38;2;$($c[0]);$($c[1]);$($c[2])m" }
function TUIx-Bg($rgb) { "$($TUI.E)[48;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m" }
function TUIx-Mix($rgb, $tint, $a) { TUIx-Bg @([int]($rgb[0] + ($tint[0] - $rgb[0]) * $a), [int]($rgb[1] + ($tint[1] - $rgb[1]) * $a), [int]($rgb[2] + ($tint[2] - $rgb[2]) * $a)) }
function TUIx-Grad($stops, $t) {
    for ($s = 1; $s -lt $stops.Count; $s++) { if ($t -le $stops[$s][0]) { break } }
    $a = $stops[$s - 1]; $b = $stops[[Math]::Min($s, $stops.Count - 1)]
    $k = if ($b[0] -gt $a[0]) { ($t - $a[0]) / ($b[0] - $a[0]) } else { 0 }
    @([int]($a[1] + ($b[1] - $a[1]) * $k), [int]($a[2] + ($b[2] - $a[2]) * $k), [int]($a[3] + ($b[3] - $a[3]) * $k))
}
function TUIx-HexOf($rgb) { '{0:X2}{1:X2}{2:X2}' -f $rgb[0], $rgb[1], $rgb[2] }

# ---------------------------------------------------------------- layout + cell cache
function TUIx-Size { try { $s = $Host.UI.RawUI.WindowSize; @([Math]::Max(40, $s.Width), [Math]::Max(16, $s.Height)) } catch { @(100, 30) } }
function TUIx-Layout {
    $ws = TUIx-Size; $W = $ws[0]; $H = $ws[1]; $th = $TUI.Th
    $TUI.W = $W; $TUI.H = $H
    $TUI.LogoTop = 1; $TUI.TagRow = 8
    $TUI.LogTop = [Math]::Min(11, [Math]::Max(3, $H - 14))
    $TUI.PanelTop = [Math]::Min($H - 5, [Math]::Max($TUI.LogTop + 4, [int]($H * 0.62)))   # lower middle
    $TUI.HintRow = $H - 2                                                                  # bottom-left key hints
    $TUI.Night = TUIx-Bg $th.night
    $TUI.BgRGB = New-Object 'object[]' $H; $TUI.BgF = New-Object 'object[]' $H
    for ($y = 0; $y -lt $H; $y++) {
        $v = 0.62 + 0.38 * [Math]::Sin([Math]::PI * ($y + 0.5) / $H)          # brighter through the middle rows
        $rgbRow = New-Object 'object[]' $W; $escRow = New-Object 'string[]' $W
        for ($x = 0; $x -lt $W; $x++) {
            $c = TUIx-Grad $th.fill ($x / [double]([Math]::Max(1, $W - 1)))
            $c = @([int]($c[0] * $v), [int]($c[1] * $v), [int]($c[2] * $v))
            $rgbRow[$x] = $c; $escRow[$x] = TUIx-Bg $c
        }
        $TUI.BgRGB[$y] = $rgbRow; $TUI.BgF[$y] = $escRow
    }
    $TUI.RowF = New-Object 'object[]' $H; $TUI.RowD = New-Object 'object[]' $H; $TUI.RowT = New-Object 'object[]' $H
    $sx = [Math]::Max(1, [Math]::Min(3, [int][Math]::Floor(($W - 6) / (TUIx-LogoWidth $TUI.Title))))
    # (assign inside the branches: an if-expression would unroll a one-item array into a plain string)
    if ($W -ge (TUIx-LogoWidth $TUI.Title) + 2) { $TUI.Logo = TUIx-LogoRows $TUI.Title $sx }
    else { $TUI.Logo = @(($TUI.Title.ToUpper().ToCharArray()) -join ' ') }
}

# One row of cells. Segments: @{ x; t = text; c = fg hex; b = solid bg hex (optional); tint = rgb + alpha = 0..1 (optional) }.
# Builds three cached strings per cell: over the fill (F), over the night background (D), and fg-only (T, for the edge).
function TUIx-Row($y, $segs) {
    if ($y -lt 0 -or $y -ge $TUI.H) { return }
    $W = $TUI.W
    $ch = New-Object 'string[]' $W; $fg = New-Object 'string[]' $W; $solid = New-Object 'string[]' $W; $tint = New-Object 'object[]' $W
    for ($x = 0; $x -lt $W; $x++) { $ch[$x] = ' ' }
    foreach ($sg in $segs) {
        $col = TUIx-Fg $sg.c
        $sb = if ($sg.b) { TUIx-Bg (TUIx-Rgb $sg.b) } else { $null }
        for ($i = 0; $i -lt $sg.t.Length; $i++) {
            $x = $sg.x + $i
            if ($x -lt 0 -or $x -ge $W) { continue }
            $ch[$x] = [string]$sg.t[$i]
            if ($ch[$x] -ne ' ' -or $sb -or $sg.tint) { $fg[$x] = $col }
            if ($sb) { $solid[$x] = $sb }
            if ($sg.tint) { $tint[$x] = @($sg.tint, $sg.alpha) }
        }
    }
    $f = New-Object 'string[]' $W; $d = New-Object 'string[]' $W; $t = New-Object 'string[]' $W
    for ($x = 0; $x -lt $W; $x++) {
        $tl = if ($fg[$x]) { $fg[$x] + $ch[$x] } else { $ch[$x] }
        if ($solid[$x]) { $t[$x] = $solid[$x] + $tl; $f[$x] = $t[$x]; $d[$x] = $t[$x] }
        elseif ($tint[$x]) {
            $t[$x] = (TUIx-Mix $TUI.BgRGB[$y][$x] $tint[$x][0] $tint[$x][1]) + $tl; $f[$x] = $t[$x]
            $d[$x] = (TUIx-Mix $TUI.Th.night $tint[$x][0] $tint[$x][1]) + $tl
        }
        else { $t[$x] = $tl; $f[$x] = $TUI.BgF[$y][$x] + $tl; $d[$x] = $TUI.Night + $tl }
    }
    $TUI.RowF[$y] = $f; $TUI.RowD[$y] = $d; $TUI.RowT[$y] = $t
}
function TUIx-Center($len) { [Math]::Max(0, [int](($TUI.W - $len) / 2)) }

# ---------------------------------------------------------------- scene pieces
function TUIx-DrawLogo {
    $logo = $TUI.Logo; $top = $TUI.LogoTop; $n = $logo.Count; $lx = TUIx-Center $logo[0].Length; $wl = [Math]::Max(1, $logo[0].Length)
    for ($r = 0; $r -le $n; $r++) {
        $segs = @()
        if ($r -ge 1) { $segs += @{ x = $lx + 1; t = $logo[$r - 1]; c = $TUI.Th.shadow } }          # shadow: 1 down, 1 right
        if ($r -lt $n) {
            $row = $logo[$r]
            for ($x = 0; $x -lt $row.Length; $x += 2) {
                $piece = $row.Substring($x, [Math]::Min(2, $row.Length - $x))
                if ($piece.Trim()) { $segs += @{ x = $lx + $x; t = $piece; c = (TUIx-HexOf (TUIx-Grad $TUI.Th.logo ((0.65 * $x / $wl) + (0.35 * $r / [Math]::Max(1, $n - 1))))) } }
            }
        }
        TUIx-Row ($top + $r) $segs
    }
}
function TUIx-DrawTags {
    if (-not $TUI.Tags) { return }
    $sep = "  $([char]0x2726)  "; $x = TUIx-Center ($TUI.Tags -join $sep).Length; $segs = @()
    for ($i = 0; $i -lt $TUI.Tags.Count; $i++) {
        $segs += @{ x = $x; t = $TUI.Tags[$i]; c = $TUI.Pal.tags[0] }; $x += $TUI.Tags[$i].Length
        if ($i -lt $TUI.Tags.Count - 1) { $segs += @{ x = $x; t = $sep; c = $TUI.Pal.sep }; $x += $sep.Length }
    }
    TUIx-Row $TUI.TagRow $segs
}
# Panel content: a prompt (message, gap, ACTION, [enter]) or the status line with %.
function TUIx-PanelLines {
    $p = $TUI.Prompt
    if (-not $p) { return @() }
    $act = if ($TUI.Lit) { $TUI.Pal.lit } else { $TUI.Pal.action }
    $out = @()
    if ($p.msg) { $out += @{ t = $p.msg; c = $TUI.Pal.text }; $out += @{ t = ''; c = $TUI.Pal.text } }
    $out += @{ t = $p.label; c = $act }
    if (-not $p.msg) { $out += @{ t = ''; c = $TUI.Pal.text } }
    $out += @{ t = $p.key; c = $TUI.Pal.key }
    return $out
}
function TUIx-PanelExtra { $n = @(TUIx-PanelLines).Count; if ($n) { $n - 1 } else { 0 } }   # rows grown above the 3-row base
function TUIx-DrawPanel {
    $lines = @(TUIx-PanelLines)
    $pct = '{0,3}%' -f [int]$TUI.Pct
    $label = "$([char]0x2726)  $($TUI.Status)"
    $need = $label.Length + $pct.Length + 12
    foreach ($l in $lines) { $need = [Math]::Max($need, $l.t.Length + 12) }
    $pw = [Math]::Min($TUI.W - 4, [Math]::Max(60, $need)); $px = TUIx-Center $pw
    $alpha = $TUI.Th.panelAlpha; if ($lines.Count -and $TUI.Lit) { $alpha += 0.05 }
    $blank = @{ x = $px; t = (' ' * $pw); c = $TUI.Pal.text; tint = $TUI.Th.panel; alpha = $alpha }
    $y = $TUI.PanelTop - (TUIx-PanelExtra)
    TUIx-Row $y @($blank); $y++
    if ($lines.Count) { foreach ($l in $lines) { TUIx-Row $y @($blank, @{ x = $px + [int](($pw - $l.t.Length) / 2); t = $l.t; c = $l.c }); $y++ } }
    elseif ($TUI.Scene -eq 'main') { TUIx-Row $y @($blank, @{ x = $px + 3; t = $label; c = $TUI.Pal.action }, @{ x = $px + $pw - $pct.Length - 3; t = $pct; c = $TUI.Pal.text }); $y++ }
    else { TUIx-Row $y @($blank); $y++ }
    TUIx-Row $y @($blank)
    TUIx-Row $TUI.HintRow @(@{ x = 2; t = $TUI.Hint; c = $TUI.Pal.dim })
}
function TUIx-DrawLogs {
    $rows = [Math]::Max(1, ($TUI.PanelTop - $TUI.LogTop - 1) - (TUIx-PanelExtra))
    $start = [Math]::Max(0, $TUI.Logs.Count - $rows)
    for ($i = 0; $i -lt $rows; $i++) {
        $j = $start + $i
        if ($j -lt $TUI.Logs.Count) { $e = $TUI.Logs[$j]; TUIx-Row ($TUI.LogTop + $i) @(@{ x = 6; t = $e.t; c = $e.c }) } else { TUIx-Row ($TUI.LogTop + $i) @() }
    }
}
function TUIx-DrawFeatures {
    $n = $TUI.Features.Count; if (-not $n) { return }
    $top0 = $TUI.LogoTop + 8; $bottom = $TUI.PanelTop - (TUIx-PanelExtra) - 1
    $gap = if (($bottom - $top0) -ge ($n * 2)) { 2 } else { 1 }
    $ftop = $top0 + [Math]::Max(0, [int](($bottom - $top0 - $n * $gap) / 2))
    for ($i = 0; $i -lt [Math]::Min($TUI.FeatShown, $n); $i++) {
        $line = "$([char]0x2726)   $(($TUI.Features[$i].ToUpper().ToCharArray()) -join ' ')   $([char]0x2726)"
        TUIx-Row ($ftop + $i * $gap) @(@{ x = (TUIx-Center $line.Length); t = $line; c = $TUI.Pal.tags[$i % $TUI.Pal.tags.Count] })
    }
}
function TUIx-DrawScene {
    for ($y = 0; $y -lt $TUI.H; $y++) { TUIx-Row $y @() }
    TUIx-DrawLogo
    if ($TUI.Scene -eq 'finale') { TUIx-DrawFeatures } else { TUIx-DrawTags; TUIx-DrawLogs }
    if ($TUI.Scene -eq 'main' -or $TUI.Prompt) { TUIx-DrawPanel } else { TUIx-Row $TUI.HintRow @(@{ x = 2; t = $TUI.Hint; c = $TUI.Pal.dim }) }
}
# Writes the whole window: filled part uses the gradient cells, a faint leading edge, then night cells.
function TUIx-Render {
    $ws = TUIx-Size
    if ($ws[0] -ne $TUI.W -or $ws[1] -ne $TUI.H) { TUIx-Layout; [Console]::Write("$($TUI.E)[2J"); TUIx-DrawScene }   # window resized
    $e = $TUI.E; $W = $TUI.W; $fill = [int][Math]::Round($W * $TUI.Pct / 100.0)
    $sb = New-Object Text.StringBuilder ($W * $TUI.H * 30)
    for ($y = 0; $y -lt $TUI.H - 1; $y++) {
        [void]$sb.Append("$e[$($y + 1);1H")
        if ($fill -gt 1) { [void]$sb.Append([string]::Join('', $TUI.RowF[$y], 0, $fill - 1)) }
        if ($fill -ge 1 -and $fill -lt $W) { [void]$sb.Append((TUIx-Mix $TUI.BgRGB[$y][$fill - 1] @(255, 255, 255) $TUI.Th.edgeAlpha) + $TUI.RowT[$y][$fill - 1]) }
        elseif ($fill -ge $W) { [void]$sb.Append($TUI.RowF[$y][$W - 1]) }
        if ($fill -lt $W) { [void]$sb.Append([string]::Join('', $TUI.RowD[$y], $fill, $W - $fill)) }
    }
    [void]$sb.Append("$e[0m")
    [Console]::Write($sb.ToString())
}
# Waits for one of $Keys (ConsoleKey names: Enter, Escape, S, ...). Pulses the prompt, follows resizes, runs $Tick each pass.
function TUIx-Key($Keys, $Tick = $null) {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $pulse = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        if ($TUI.Demo -and $sw.ElapsedMilliseconds -gt 2500) { return $Keys[0] }
        $avail = $false; try { $avail = [Console]::KeyAvailable } catch {}
        if ($avail) { $k = [Console]::ReadKey($true).Key.ToString(); if ($Keys -contains $k) { return $k } }
        if ($Tick) { $r = & $Tick; if ($r) { return $r } }
        if ($TUI.Prompt -and $pulse.ElapsedMilliseconds -gt 480) { $pulse.Restart(); $TUI.Lit = -not $TUI.Lit; TUIx-DrawPanel; if ($TUI.Scene -eq 'main') { TUIx-DrawLogs } }
        TUIx-Render
        Start-Sleep -Milliseconds 60
    }
}
function TUIx-PlainColor($kind) { @{ text = 'White'; ok = 'Green'; warn = 'Yellow'; info = 'Gray'; err = 'Red'; dim = 'DarkGray' }[$kind] }
function TUIx-PlainKey($answer, $Keys) {
    $a = ([string]$answer).Trim().ToUpper()
    if (-not $a) { return $Keys[0] }
    if ($a -in 'N', 'Q', 'NO' -and $Keys -contains 'Escape') { return 'Escape' }
    foreach ($k in $Keys) { if ($k.ToUpper() -eq $a -or $k.ToUpper().StartsWith($a)) { return $k } }
    return $Keys[0]
}

# ================================================================ public API
# Starts the UI. -Plain forces plain text; -Demo answers prompts by itself after 2.5 s (screenshots, tests).
function TUI-Init {
    param([string]$Title = 'SETUP', [string[]]$Tags = @(), [string]$Theme = 'nightreign', [switch]$Plain, [switch]$Demo, [string]$WindowTitle)
    $script:ProgressPreference = 'SilentlyContinue'      # PowerShell's own progress bars (Expand-Archive...) would draw over the UI
    $TUI.Title = $Title; $TUI.Tags = $Tags; $TUI.Demo = [bool]$Demo
    $TUI.Logs = New-Object System.Collections.ArrayList; $TUI.Features = @(); $TUI.FeatShown = 0
    $TUI.Pct = 0.0; $TUI.Scene = 'main'; $TUI.Prompt = $null; $TUI.Status = ''; $TUI.Hint = ''; $TUI.Lit = $false
    TUI-SetTheme $Theme -NoDraw
    try { $Host.UI.RawUI.WindowTitle = $(if ($WindowTitle) { $WindowTitle } else { "$Title setup" }) } catch {}
    $fancy = -not $Plain
    try { if ([Console]::IsOutputRedirected -or [Console]::IsInputRedirected) { $fancy = $false } } catch { $fancy = $false }
    if ($fancy) {
        try {
            if (-not ('TUIx.Con' -as [type])) {
                Add-Type -Namespace TUIx -Name Con -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern System.IntPtr GetStdHandle(int n);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(System.IntPtr h, out uint m);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(System.IntPtr h, uint m);
'@
            }
            $h = [TUIx.Con]::GetStdHandle(-11); $mode = 0
            if (-not [TUIx.Con]::GetConsoleMode($h, [ref]$mode)) { throw 'no console' }
            if (-not [TUIx.Con]::SetConsoleMode($h, ($mode -bor 0x4))) { throw 'no VT' }   # ENABLE_VIRTUAL_TERMINAL_PROCESSING
            $TUI.OldEnc = [Console]::OutputEncoding
            [Console]::OutputEncoding = [Text.Encoding]::UTF8
        } catch { $fancy = $false }
    }
    $TUI.Fancy = $fancy; $TUI.Plain = -not $fancy
    if ($fancy) {
        TUIx-Layout; TUIx-DrawScene
        [Console]::Write("$($TUI.E)[?1049h$($TUI.E)[?25l$($TUI.E)[2J")   # own screen buffer in this window, hidden cursor
        $TUI.InAlt = $true
        TUIx-Render
    } else { TUIx-PlainBanner }
}
function TUI-SetTheme([string]$Name, [switch]$NoDraw) {
    $th = $script:TUI_THEMES[$Name]; if (-not $th) { $th = $script:TUI_THEMES['nightreign']; $Name = 'nightreign' }
    if (-not $th.panelAlpha) { $th.panelAlpha = 0.16 }; if (-not $th.edgeAlpha) { $th.edgeAlpha = 0.18 }
    $TUI.Th = $th; $TUI.Pal = $th.pal; $TUI.ThemeName = $Name
    if ($TUI.Fancy -and -not $NoDraw) { TUIx-Layout; TUIx-DrawScene; TUIx-Render }
}
function TUI-Leave {
    if ($TUI.InAlt) {
        [Console]::Write("$($TUI.E)[0m$($TUI.E)[?25h$($TUI.E)[?1049l"); $TUI.InAlt = $false
        if ($TUI.OldEnc) { [Console]::OutputEncoding = $TUI.OldEnc }
    }
}
function TUI-Fail([string]$Message) { TUI-Leave; Write-Host "`n    ERROR: $Message" -ForegroundColor Red; exit 1 }

# Adds a log line. Kinds: text ok warn info err dim.
function TUI-Log([string]$Message, [string]$Kind = 'info') {
    if (-not $TUI.Fancy) { Write-Host "    $Message" -ForegroundColor (TUIx-PlainColor $Kind); return }
    $max = [Math]::Max(20, $TUI.W - 10); $c = $TUI.Pal[$Kind]; if (-not $c) { $c = $TUI.Pal.info }
    foreach ($part in @($Message -split "`n")) {
        while ($part.Length -gt $max) { [void]$TUI.Logs.Add(@{ t = $part.Substring(0, $max); c = $c }); $part = '  ' + $part.Substring($max) }
        [void]$TUI.Logs.Add(@{ t = $part; c = $c })
    }
    TUIx-DrawLogs; TUIx-Render
}
# Sets the status line in the panel (and the bottom-left key hint).
function TUI-Status([string]$Text, [string]$Hint = '') {
    $TUI.Status = $Text; $TUI.Hint = $Hint
    if (-not $TUI.Fancy) { Write-Host ''; Write-Host "  $([char]0x2726) " -ForegroundColor DarkMagenta -NoNewline; Write-Host $Text -ForegroundColor White; if ($Hint) { Write-Host "    $Hint" -ForegroundColor DarkGray }; return }
    TUIx-DrawPanel; TUIx-Render
}
# Animates the background fill to $Percent over $Ms milliseconds.
function TUI-Progress([double]$Percent, [int]$Ms = 700) {
    if (-not $TUI.Fancy) { $TUI.Pct = $Percent; return }
    $from = $TUI.Pct; $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        $k = [Math]::Min(1.0, $sw.ElapsedMilliseconds / [double][Math]::Max(1, $Ms))
        $TUI.Pct = $from + ($Percent - $from) * (1 - [Math]::Pow(1 - $k, 3))   # ease out
        TUIx-DrawPanel; TUIx-Render
        if ($k -ge 1) { break }
        Start-Sleep -Milliseconds 12
    }
}
# Shows a prompt in the panel (optional message line, ACTION in the accent colour, key label) and waits.
# Returns the ConsoleKey name pressed (first of -Keys on Enter / blank answer in plain mode).
function TUI-Prompt {
    param([string]$Label, [string]$Message, [string[]]$Keys = @('Enter', 'Escape'), [string]$Hint = '', [string]$KeyLabel = '[enter]')
    if (-not $TUI.Fancy) {
        if ($Message) { Write-Host "`n    $Message" -ForegroundColor White }
        if ($Hint) { Write-Host "    $Hint" -ForegroundColor DarkGray }
        return TUIx-PlainKey (Read-Host "    $Label (Enter)") $Keys
    }
    $oldHint = $TUI.Hint
    $TUI.Prompt = @{ label = $Label; msg = $Message; key = $KeyLabel }; $TUI.Hint = $Hint; $TUI.Lit = $false
    TUIx-DrawScene; TUIx-Render
    $k = TUIx-Key $Keys
    $TUI.Prompt = $null; $TUI.Hint = $oldHint; TUIx-DrawScene; TUIx-Render
    return $k
}
# Waits until $Poll returns $true (checked every $PollMs) or one of $Keys is pressed. Shows a spinner + elapsed seconds.
# Returns 'done' or the key name.
function TUI-Wait {
    param([string]$Status, [scriptblock]$Poll, [string[]]$Keys = @(), [string]$Hint = '', [int]$PollMs = 1000)
    $sw = [Diagnostics.Stopwatch]::StartNew(); $next = 0; $spin = '|/-\'
    if (-not $TUI.Fancy) {
        Write-Host "    $Status...  $Hint" -ForegroundColor Cyan
        while ($true) {
            $avail = $false; try { $avail = [Console]::KeyAvailable } catch {}
            if ($avail) { $k = [Console]::ReadKey($true).Key.ToString(); if ($Keys -contains $k) { return $k } }
            if ($sw.ElapsedMilliseconds -ge $next) { $next = $sw.ElapsedMilliseconds + $PollMs; if (& $Poll) { return 'done' } }
            Start-Sleep -Milliseconds 120
        }
    }
    $TUI.Hint = $Hint
    return TUIx-WaitLoop $Keys $Status $Poll $PollMs
}
function TUIx-WaitLoop($Keys, $Status, $Poll, $PollMs) {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $next = 0; $i = 0; $spin = '|/-\'; $lastSpin = -1000
    while ($true) {
        if ($TUI.Demo -and $sw.ElapsedMilliseconds -gt 60000) { return 'done' }
        $avail = $false; try { $avail = [Console]::KeyAvailable } catch {}
        if ($avail) { $k = [Console]::ReadKey($true).Key.ToString(); if ($Keys -contains $k) { return $k } }
        if ($sw.ElapsedMilliseconds - $lastSpin -ge 120) {
            $lastSpin = $sw.ElapsedMilliseconds
            $TUI.Status = "$Status  $($spin[$i % 4])   $([int]$sw.Elapsed.TotalSeconds)s"; $i++
            TUIx-DrawPanel; TUIx-Render
        }
        if ($sw.ElapsedMilliseconds -ge $next) { $next = $sw.ElapsedMilliseconds + $PollMs; if (& $Poll) { return 'done' } }
        Start-Sleep -Milliseconds 40
    }
}
# Asks for a line of text (shown at the bottom-left).
function TUI-ReadLine([string]$Prompt) {
    if (-not $TUI.Fancy) { return ([string](Read-Host "    $Prompt")).Trim().Trim('"') }
    $e = $TUI.E
    TUIx-Row $TUI.HintRow @(); TUIx-Render
    [Console]::Write("$e[$($TUI.HintRow + 1);3H$($TUI.Night)$(TUIx-Fg $TUI.Pal.text)$e[?25h")
    $a = Read-Host $Prompt
    [Console]::Write("$e[?25l"); TUIx-DrawScene; TUIx-Render
    return ([string]$a).Trim().Trim('"')
}
# Finale on one page: title, features revealed one by one, then the action prompt. Returns $true on Enter, $false on Esc.
function TUI-Finale {
    param([string[]]$Features = @(), [string]$Label = 'PLAY', [string]$Hint = '[Esc] close', [string]$KeyLabel = '[enter]')
    if (-not $TUI.Fancy) {
        Write-Host ''; foreach ($f in $Features) { Write-Host "      $([char]0x2726)  $f" -ForegroundColor Cyan }
        return (TUIx-PlainKey (Read-Host "`n    Press Enter to $Label (N = close)") @('Enter', 'Escape')) -eq 'Enter'
    }
    $TUI.Pct = 100; $TUI.Scene = 'finale'; $TUI.Features = $Features; $TUI.FeatShown = 0; $TUI.Prompt = $null; $TUI.Hint = ''
    TUIx-DrawScene; TUIx-Render; Start-Sleep -Milliseconds 700
    for ($i = 1; $i -le $Features.Count; $i++) { $TUI.FeatShown = $i; TUIx-DrawScene; TUIx-Render; Start-Sleep -Milliseconds 450 }
    Start-Sleep -Milliseconds 300
    $TUI.Prompt = @{ label = $Label; msg = $null; key = $KeyLabel }; $TUI.Hint = $Hint; $TUI.Lit = $false
    TUIx-DrawScene; TUIx-Render
    return (TUIx-Key @('Enter', 'Escape')) -eq 'Enter'
}

function TUIx-PlainBanner {
    $W = 100; try { $W = $Host.UI.RawUI.WindowSize.Width } catch {}
    $sx = [Math]::Max(1, [Math]::Min(2, [int][Math]::Floor(($W - 4) / (TUIx-LogoWidth $TUI.Title))))
    $rows = TUIx-LogoRows $TUI.Title $sx
    $pad = ' ' * [Math]::Max(0, [int](($W - $rows[0].Length) / 2))
    Write-Host ''
    $colors = 'White', 'Gray', 'Gray', 'DarkGray', 'DarkGray'
    for ($r = 0; $r -lt 5; $r++) { Write-Host ($pad + $rows[$r]) -ForegroundColor $colors[$r] }
    if ($TUI.Tags) {
        $line = $TUI.Tags -join "  $([char]0x2726)  "
        Write-Host ''; Write-Host ((' ' * [Math]::Max(0, [int](($W - $line.Length) / 2))) + $line) -ForegroundColor Cyan
    }
}
