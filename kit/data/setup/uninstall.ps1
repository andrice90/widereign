# WideReign (nrwide) uninstaller. Run through Uninstall.bat (a copy lives in the install folder).
#   -KeepSeamless        remove nrwide only, leave Seamless Co-op in the game folder
#   -ShortcutDir <path>  where the shortcuts are (default: Desktop)
#   -Yes                 no questions
# Never touches game files or save files. Only removes files listed in game_files.txt that the installer added.
param(
    [switch]$KeepSeamless,
    [string]$ShortcutDir = [Environment]::GetFolderPath('Desktop'),
    [switch]$Yes
)
$ErrorActionPreference = 'Stop'
$InstallDir = $PSScriptRoot
function Say($m, $c = 'Gray') { Write-Host $m -ForegroundColor $c }

if (-not (Test-Path (Join-Path $InstallDir 'nrwide_launcher.exe')) -and -not (Test-Path (Join-Path $InstallDir 'game_files.txt'))) {
    Say "This doesn't look like an nrwide install folder: $InstallDir" Red; exit 1
}

$ini = Join-Path $InstallDir 'nrwide.ini'
$GameDir = $null
if (Test-Path $ini) {
    $m = [regex]::Match([IO.File]::ReadAllText($ini), '(?m)^\s*game_dir\s*=\s*([^\r\n]*)')
    if ($m.Success) { $GameDir = $m.Groups[1].Value.Trim().TrimEnd('\') }
}
if ($GameDir -and (Get-Process nightreign -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $GameDir 'nightreign.exe') })) {
    Say 'The game is running. Close it first.' Red; exit 1
}

if (-not $Yes -and -not $KeepSeamless) {
    $a = Read-Host 'Also remove Seamless Co-op from the game folder? (your saves are kept either way) [Y/n]'
    if ($a -and -not $a.Trim().ToLower().StartsWith('y')) { $KeepSeamless = $true }
}

# game folder: only files we added, never the game's own
$protected = '^(nightreign\.exe|start_protected_game\.exe|regulation\.bin|steam_api64\.dll|bink2w64\.dll|amd_ags_x64\.dll|oo2core_\d+_win64\.dll|eossdk-.*|data\d\.(bdt|bhd)|steam_input.*\.vdf)$|^(easyanticheat|movie|sd)\\'
$manifestPath = Join-Path $InstallDir 'game_files.txt'
if ($GameDir -and (Test-Path $GameDir) -and (Test-Path $manifestPath)) {
    if ($KeepSeamless) {
        # Seamless Co-op files and steam_appid.txt (Seamless needs it too) stay
        Say 'Seamless Co-op left in place in the game folder.'
    } else {
        $removed = 0
        $dirs = @{}
        foreach ($rel in (Get-Content $manifestPath | Where-Object { $_ })) {
            if ($rel -match '\.\.' -or [IO.Path]::IsPathRooted($rel) -or $rel -match $protected) { continue }
            $p = Join-Path $GameDir $rel
            if (Test-Path $p -PathType Leaf) { Remove-Item $p -Force; $removed++ }
            $d = Split-Path $p
            while ($d.Length -gt $GameDir.Length) { $dirs[$d] = 1; $d = Split-Path $d }
        }
        # remove folders that held our files (SeamlessCoop\ ...) once empty; never the game folder itself
        foreach ($d in ($dirs.Keys | Sort-Object Length -Descending)) {
            if ((Test-Path $d) -and -not (Get-ChildItem $d -Force)) { Remove-Item $d -Force }
        }
        Say "Removed $removed added files from the game folder." Green
    }
}

# shortcuts: only ours (target is our launcher)
$sh = New-Object -ComObject WScript.Shell
$launcher = Join-Path $InstallDir 'nrwide_launcher.exe'
foreach ($l in Get-ChildItem (Join-Path $ShortcutDir '*.lnk') -ErrorAction SilentlyContinue) {
    if ($sh.CreateShortcut($l.FullName).TargetPath -eq $launcher) { Remove-Item $l.FullName -Force }
}

# install folder (Uninstall.bat deletes itself and the folder afterwards)
Get-ChildItem $InstallDir -Force | Where-Object { $_.Name -ne 'Uninstall.bat' } | Remove-Item -Recurse -Force
Say 'WideReign removed.' Green
