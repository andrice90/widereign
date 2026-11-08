# WideReign installer (nrwide + Seamless Co-op). Run through Install.bat. UI: tui.ps1 (same folder).
# Works with ELDEN RING NIGHTREIGN (Steam). Not affiliated with FromSoftware or Bandai Namco.
#
#   -GameDir <path>      folder that holds nightreign.exe (default: found through Steam)
#   -SeamlessZip <path>  Seamless Co-op zip or extracted folder (default: newest match in Downloads)
#   -SkipSeamless        install nrwide only
#   -InstallDir <path>   where nrwide goes (default: %LOCALAPPDATA%\nrwide)
#   -ShortcutDir <path>  where the shortcuts go (default: Desktop)
#   -Plain               no full-window UI       -Yes  never wait for input (tests; implies -Plain)
#   -DryRun              full run, but every write goes to %TEMP%\widereign-dryrun and PLAY launches nothing
#   -Demo                UI answers its own prompts (screenshots)      -DownloadsDir / -NoBrowser  tests
param(
    [string]$GameDir,
    [string]$SeamlessZip,
    [switch]$SkipSeamless,
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'nrwide'),
    [string]$ShortcutDir = [Environment]::GetFolderPath('Desktop'),
    [switch]$Plain,
    [switch]$Yes,
    [switch]$DryRun,
    [switch]$Demo,
    [string]$DownloadsDir = (Join-Path $env:USERPROFILE 'Downloads'),
    [switch]$NoBrowser
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'tui.ps1')

$kit = Split-Path -Parent $PSScriptRoot          # data\ (has files\ and setup\)
$AppId = '2622380'
$NexusUrl = 'https://www.nexusmods.com/eldenringnightreign/mods/3?tab=files'
$Features = 'Co-op', '21x9', '>60fps', 'Thicc Margot'

# kit.ini: seamless_version = the version the group plays; theme = nightreign | neon | ember | frost
$want = $null; $theme = 'nightreign'
$kitIni = Join-Path $PSScriptRoot 'kit.ini'
if (Test-Path $kitIni) {
    $iniText = Get-Content $kitIni -Raw
    $m = [regex]::Match($iniText, '(?m)^\s*seamless_version\s*=\s*v?([0-9.]+)'); if ($m.Success) { $want = $m.Groups[1].Value }
    $m = [regex]::Match($iniText, '(?m)^\s*theme\s*=\s*([a-z]+)'); if ($m.Success) { $theme = $m.Groups[1].Value }
}
if ($DryRun) {
    $Sandbox = Join-Path $env:TEMP 'widereign-dryrun'
    if (Test-Path $Sandbox) { Remove-Item -LiteralPath $Sandbox -Recurse -Force }
    $InstallDir = Join-Path $Sandbox 'install'; $ShortcutDir = Join-Path $Sandbox 'Desktop'
    New-Item -ItemType Directory -Force (Join-Path $Sandbox 'Game') | Out-Null
}

function Find-Game {
    $roots = @()
    foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
        try { $p = (Get-ItemProperty $k -ErrorAction Stop); $roots += @($p.SteamPath, $p.InstallPath) } catch {}
    }
    $libs = @()
    foreach ($r in ($roots | Where-Object { $_ } | Select-Object -Unique)) {
        $libs += $r
        $vdf = Join-Path $r 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) { foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value -replace '\\\\', '\' } }
    }
    foreach ($l in ($libs | Select-Object -Unique)) {
        $g = Join-Path $l 'steamapps\common\ELDEN RING NIGHTREIGN\Game'
        if (Test-Path (Join-Path $g 'nightreign.exe')) { return $g }
    }
    return $null
}
function Find-ScZip {
    Get-ChildItem (Join-Path $DownloadsDir '*.zip') -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'seamless|nrsc' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
function Get-ScVersion($s) { $m = [regex]::Match([string]$s, 'v(\d+(\.\d+){1,3})'); if ($m.Success) { $m.Groups[1].Value } }

TUI-Init -Title 'WIDEREIGN' -Tags $Features -Theme $theme -Plain:($Plain -or $Yes) -Demo:$Demo -WindowTitle 'WideReign setup'
try {
    # ---------- 0. confirm ----------
    if (-not $Yes) {
        if ((TUI-Prompt -Label 'INSTALL WIDEREIGN?' -Hint '[Esc] cancel') -eq 'Escape') { TUI-Leave; Write-Host '    Cancelled.'; exit 0 }
    }

    # ---------- 1. find the game ----------
    TUI-Status 'Finding the game'
    if (-not $GameDir) { $GameDir = Find-Game }
    if (-not $GameDir) {
        TUI-Log "Couldn't find NIGHTREIGN through Steam." 'warn'
        if ($Yes) { TUI-Fail 'Pass -GameDir.' }
        $GameDir = TUI-ReadLine 'Paste the game folder (the one with nightreign.exe)'
    }
    if (-not $GameDir -or -not (Test-Path (Join-Path $GameDir 'nightreign.exe'))) { TUI-Fail "nightreign.exe not found in '$GameDir'." }
    $GameDir = (Resolve-Path $GameDir).Path.TrimEnd('\')
    $exe = Join-Path $GameDir 'nightreign.exe'
    $GameOut = if ($DryRun) { Join-Path $Sandbox 'Game' } else { $GameDir }   # where game-folder files are written
    if (Get-Process nightreign -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }) { TUI-Fail 'The game is running. Close it and run Install.bat again.' }
    TUI-Log "Game: $GameDir" 'ok'
    if ($DryRun) { TUI-Log "DRY RUN: nothing is installed for real. Writes go to $Sandbox" 'warn' }
    TUI-Progress 12

    # admin only if the game folder isn't writable
    $probe = Join-Path $GameOut ('nrwide_probe_' + [guid]::NewGuid().ToString('N'))
    try { [IO.File]::WriteAllText($probe, 'x'); Remove-Item $probe -Force; $writable = $true } catch { $writable = $false }
    if (-not $writable) {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($isAdmin) { TUI-Fail "Can't write to $GameDir even as administrator." }
        TUI-Leave
        Write-Host '    The game folder needs administrator rights. Asking Windows...' -ForegroundColor Yellow
        $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-GameDir', "`"$GameDir`"",
               '-InstallDir', "`"$InstallDir`"", '-ShortcutDir', "`"$ShortcutDir`"", '-DownloadsDir', "`"$DownloadsDir`"")
        if ($SeamlessZip) { $a += @('-SeamlessZip', "`"$SeamlessZip`"") }
        if ($SkipSeamless) { $a += '-SkipSeamless' }
        if ($Yes) { $a += '-Yes' }
        if ($Plain) { $a += '-Plain' }
        Start-Process powershell -Verb RunAs -ArgumentList $a -Wait
        exit 0
    }

    # ---------- 2. WideReign files ----------
    TUI-Status 'Installing WideReign'
    $manifestPath = Join-Path $InstallDir 'game_files.txt'   # files we put into the game folder (uninstall removes exactly these)
    New-Item -ItemType Directory -Force $InstallDir | Out-Null
    $manifest = [Collections.Generic.List[string]]::new()
    if (Test-Path $manifestPath) { $manifest.AddRange([string[]](Get-Content $manifestPath | Where-Object { $_ })) }
    foreach ($f in 'nrwide.dll', 'nrwide_launcher.exe') { Copy-Item (Join-Path $kit "files\$f") $InstallDir -Force }
    Copy-Item (Join-Path $kit 'README.txt') $InstallDir -Force -ErrorAction SilentlyContinue
    foreach ($f in 'uninstall.ps1', 'Uninstall.bat') { Copy-Item (Join-Path $PSScriptRoot $f) $InstallDir -Force }
    Get-ChildItem $InstallDir -File | Unblock-File -ErrorAction SilentlyContinue

    # ini: start from the kit's, carry over the player's values (FOV, fps cap...) from an older install
    $ini = Join-Path $InstallDir 'nrwide.ini'
    $text = [IO.File]::ReadAllText((Join-Path $kit 'files\nrwide.ini'))
    if (Test-Path $ini) {
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($ini), '(?m)^\s*([a-z0-9_]+)\s*=\s*([^\r\n]*)')) {
            $key = [regex]::Escape($m.Groups[1].Value); $val = $m.Groups[2].Value
            $text = [regex]::Replace($text, "(?m)^(\s*$key\s*=)[^\r\n]*", { param($x) $x.Groups[1].Value + $val })
        }
    }
    $text = [regex]::Replace($text, '(?m)^(\s*game_dir\s*=)[^\r\n]*', { param($x) $x.Groups[1].Value + $GameDir })
    [IO.File]::WriteAllText($ini, $text, [Text.Encoding]::Unicode)   # UTF-16 so GetPrivateProfileString reads any path

    # steam_appid.txt lets nightreign.exe start without Steam relaunching it through anti-cheat
    $appid = Join-Path $GameOut 'steam_appid.txt'
    if (-not (Test-Path $appid)) {
        [IO.File]::WriteAllText($appid, $AppId)
        if (-not $manifest.Contains('steam_appid.txt')) { $manifest.Add('steam_appid.txt') }
    }
    TUI-Log "WideReign: $InstallDir" 'ok'
    TUI-Progress 30

    # ---------- 3. Seamless Co-op ----------
    $haveSc = Test-Path (Join-Path $GameOut 'nrsc_launcher.exe')
    if (-not $SkipSeamless) {
        TUI-Status 'Seamless Co-op'
        if ($want) { TUI-Log "Your group plays Seamless Co-op v$want." 'info' }
        if (-not $SeamlessZip) { $z = Find-ScZip; if ($z) { $SeamlessZip = $z.FullName } }
        TUI-Progress 40

        if (-not $SeamlessZip -and -not $haveSc -and -not $Yes) {
            $k = TUI-Prompt -Label 'OPEN NEXUS MODS' -Message 'This mod needs Seamless Co-op downloaded from Nexus Mods' -Keys 'Enter', 'S'
            if ($k -eq 'Enter') {
                if (-not $NoBrowser) { Start-Process $NexusUrl }
                TUI-Log "On that page: Files tab > Main file$(if ($want) { " v$want" }) > Manual Download (free Nexus account)." 'info'
                TUI-Log 'Leave the zip in your Downloads folder. I will pick it up.' 'info'
                $script:lastZip = $null; $script:lastSize = -1
                $r = TUI-Wait -Status 'Waiting for the Seamless Co-op download' -Keys 'S', 'P' -Hint '[S] skip co-op      [P] type a path' -Poll {
                    $z = Find-ScZip
                    $busy = Get-ChildItem $DownloadsDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.crdownload', '.part', '.tmp' }
                    if (-not $z -or $busy) { return $false }
                    if ($script:lastZip -eq $z.FullName -and $script:lastSize -eq $z.Length) { $script:SeamlessZip = $z.FullName; return $true }   # size held still: done
                    $script:lastZip = $z.FullName; $script:lastSize = $z.Length; return $false
                }
                if ($r -eq 'P') { $SeamlessZip = TUI-ReadLine 'Path to the zip or extracted folder' }
            }
            TUI-Status 'Seamless Co-op'
        }

        if ($SeamlessZip) {
            if (-not (Test-Path $SeamlessZip)) { TUI-Fail "Not found: $SeamlessZip" }
            $got = Get-ScVersion (Split-Path $SeamlessZip -Leaf)
            TUI-Log "Using $(Split-Path $SeamlessZip -Leaf)" 'info'
            if ($want -and $got -and $got -ne $want) { TUI-Log "Heads up: this is v$got but your group plays v$want. Different versions can't join each other." 'warn' }
            TUI-Progress 55
            $tmp = $null
            if ((Get-Item $SeamlessZip).PSIsContainer) { $root = $SeamlessZip }
            else {
                if ([IO.Path]::GetExtension($SeamlessZip) -ne '.zip') { TUI-Fail 'Only .zip is supported. Extract it and give the folder path instead.' }
                $tmp = Join-Path $env:TEMP ('nrwide_sc_' + [guid]::NewGuid().ToString('N'))
                Expand-Archive -LiteralPath $SeamlessZip -DestinationPath $tmp
                $root = $tmp
            }
            $l = Get-ChildItem $root -Recurse -File -Filter 'nrsc_launcher.exe' | Select-Object -First 1
            if (-not $l) { TUI-Fail "nrsc_launcher.exe not found inside $SeamlessZip. Is this the Nightreign Seamless Co-op download?" }
            $base = $l.DirectoryName.TrimEnd('\'); $count = 0
            foreach ($f in Get-ChildItem $base -Recurse -File) {
                $rel = $f.FullName.Substring($base.Length + 1)
                $dst = Join-Path $GameOut $rel
                if ($rel -match 'nrsc_settings\.ini$' -and (Test-Path $dst)) { continue }   # keep the player's settings
                New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
                Copy-Item $f.FullName $dst -Force
                Unblock-File $dst -ErrorAction SilentlyContinue
                if (-not $manifest.Contains($rel)) { $manifest.Add($rel) }
                $count++
            }
            if ($tmp) { Remove-Item $tmp -Recurse -Force }
            TUI-Log "Seamless Co-op installed ($count files)" 'ok'
            $haveSc = $true
        } elseif ($haveSc) { TUI-Log 'Seamless Co-op already installed' 'ok' }
        else { TUI-Log 'Co-op skipped. Solo still works; run Install.bat again later to add co-op.' 'warn' }
        TUI-Progress 80
    }
    $manifest | Set-Content $manifestPath -Encoding UTF8

    # ---------- 4. shortcuts ----------
    TUI-Status 'Desktop shortcuts'
    $launcher = Join-Path $InstallDir 'nrwide_launcher.exe'
    $sh = New-Object -ComObject WScript.Shell
    New-Item -ItemType Directory -Force $ShortcutDir | Out-Null
    foreach ($old in Get-ChildItem (Join-Path $ShortcutDir '*.lnk') -ErrorAction SilentlyContinue) {   # older kits' names, only if ours
        if ($old.BaseName -match '^(Nightreign Ultrawide|ELDEN BOIS)' -and $sh.CreateShortcut($old.FullName).TargetPath -eq $launcher) { Remove-Item $old.FullName -Force }
    }
    function Make-Link($name, $mode) {
        $lnk = $sh.CreateShortcut((Join-Path $ShortcutDir "$name.lnk"))
        $lnk.TargetPath = $launcher; $lnk.Arguments = "--mode $mode"; $lnk.WorkingDirectory = $InstallDir
        $lnk.IconLocation = "$exe,0"; $lnk.Description = "WideReign ($mode)"; $lnk.Save()
        TUI-Log "Shortcut: $name" 'ok'
    }
    Make-Link 'WideReign (solo)' 'direct'
    if ($haveSc) { Make-Link 'WideReign (coop)' 'seamless' } else { Remove-Item (Join-Path $ShortcutDir 'WideReign (coop).lnk') -ErrorAction SilentlyContinue }
    TUI-Progress 92

    try {   # read-only check
        $sac = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -ErrorAction Stop).VerifiedAndReputablePolicyState
        if ($sac -eq 1) { TUI-Log 'Windows Smart App Control is ON. It blocks unsigned DLLs like nrwide.dll, so the mod may not load.' 'warn' }
    } catch {}

    TUI-Status 'WideReign is ready'
    TUI-Progress 100 1100
    TUI-Log 'Ready. Press F7 / F8 in game for FOV.' 'text'
    Start-Sleep -Milliseconds 700

    # ---------- finale ----------
    $mode = if ($haveSc) { 'seamless' } else { 'direct' }
    $play = if ($Yes) { $false } else { TUI-Finale -Features $Features -Label 'PLAY WIDEREIGN' -Hint "$(if ($haveSc) { 'starts co-op (Seamless Co-op)' } else { 'starts solo' })      [Esc] close" }
    TUI-Leave
    Write-Host ''
    Write-Host "  $([char]0x2726) WideReign installed$(if ($DryRun) { ' (dry run)' })." -ForegroundColor Magenta
    Write-Host "    Shortcuts: WideReign (solo)$(if ($haveSc) { ', WideReign (coop)' })" -ForegroundColor Gray
    Write-Host "    Settings:  $ini" -ForegroundColor Gray
    Write-Host "    Uninstall: Uninstall.bat (or $InstallDir\Uninstall.bat)" -ForegroundColor Gray
    Write-Host '    In game: F7 = wider FOV, F8 = narrower.' -ForegroundColor Gray
    Write-Host "    Steam's normal Play button is unchanged (official online, no mods)." -ForegroundColor DarkGray
    if ($play) {
        if ($DryRun -or $Demo) { Write-Host "`n    PLAY pressed: would start  nrwide_launcher.exe --mode $mode" -ForegroundColor Yellow }
        else {
            Start-Process -FilePath $launcher -ArgumentList "--mode $mode" -WorkingDirectory $InstallDir
            Write-Host "`n    Starting WideReign ($(if ($mode -eq 'seamless') { 'coop' } else { 'solo' }))..." -ForegroundColor Yellow
        }
    }
    Write-Host ''
    if ($DryRun -and -not $Yes -and -not $Demo) { [void](Read-Host '    Dry run finished. Press Enter to close') }
} catch {
    TUI-Fail "$($_.Exception.Message)  [line $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())]"
} finally {
    TUI-Leave
}
