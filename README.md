# WideReign

**Co-op ✦ 21:9 ✦ >60 FPS ✦ FOV** for ELDEN RING NIGHTREIGN on PC (Steam).

An unofficial mod that removes the 16:9 black bars on ultrawide monitors, raises the 60 FPS cap, stops fullscreen
forcing 60 Hz, and adds an in-game FOV adjust, with a one-click installer that also sets up
[Seamless Co-op](https://www.nexusmods.com/eldenringnightreign/mods/3) so you can play with friends while modded.

> **Offline / Seamless Co-op only.** WideReign starts the game **without Easy Anti-Cheat**. It never runs in official
> online play, and you should not try to make it. Steam's normal **Play** button is untouched and stays online with EAC.
>
> Not affiliated with or endorsed by FromSoftware or Bandai Namco. You need your own copy of the game.
> No game files are included in this repository or its releases.

## Features

- **Ultrawide:** removes the pillarbox at 21:9 and 32:9. The HUD stays a centred 16:9.
- **High frame rate:** raises the 60 FPS cap (default: your monitor's refresh rate, or set your own).
- **No forced 60 Hz:** exclusive fullscreen keeps your refresh rate.
- **FOV:** in game, **F7** = wider, **F8** = narrower, in 5° steps added to the game's own FOV.
  The value is saved and restored on the next launch.
- **Patched before the game boots**, so no windowed/borderless toggle is needed (solo mode).
- **Installer:** a full-window terminal UI that finds the game through Steam, fetches Seamless Co-op from Nexus Mods
  (it opens the page and waits for your download), and creates desktop shortcuts. It also uninstalls cleanly.

## Install

1. Download `widereign-mod.zip` from the [Releases](../../releases) page and unzip it anywhere.
2. Double-click **`Install.bat`** and press Enter.
   - If Seamless Co-op isn't in your Downloads folder, press Enter to open its Nexus Mods page.
     Download the **Main file** (free Nexus account). The installer picks the zip up by itself.
3. Use the desktop shortcuts, with Steam running:
   - **WideReign (coop)**: play with friends through Seamless Co-op.
   - **WideReign (solo)**: play alone, offline.
4. In game: **Graphics**, then set your ultrawide resolution.

Run `Install.bat` again to update; your settings are kept.

**Co-op notes:** every player needs Seamless Co-op, all on the **same version**. Friends don't need WideReign; it only
changes your own screen and frame rate. Seamless Co-op uses its own save file, so your normal online save is untouched.

## Uninstall

Double-click **`Uninstall.bat`**, or run `%LOCALAPPDATA%\nrwide\Uninstall.bat`. It removes WideReign, its shortcuts
and (if you say yes) the Seamless Co-op files it installed. It deletes only files the installer recorded adding,
never game files or saves.

## Settings

`%LOCALAPPDATA%\nrwide\nrwide.ini`:

| key | default | |
|---|---|---|
| `ultrawide` | 1 | remove the black bars |
| `fps_unlock` | 1 | raise the frame cap |
| `fps_limit` | 0 | 0 = monitor refresh rate, otherwise 30-1000 |
| `remove_60hz_lock` | 1 | keep your refresh rate in exclusive fullscreen |
| `fov` | 1 | F7/F8 FOV adjust |
| `fov_offset` | 0 | degrees added to the game FOV (F7/F8 write this) |
| `fov_step` / `fov_min` / `fov_max` | 5 / -30 / 60 | step and limits |
| `fov_up_key` / `fov_down_key` | 118 / 119 | virtual-key codes (F7 / F8) |
| `[launcher] mode` | direct | `direct` = solo offline, `seamless` = through Seamless Co-op (the shortcuts pass `--mode`) |
| `seamless_launcher` / `seamless_module` | nrsc_launcher.exe / nrsc.dll | only change if Seamless Co-op renames them |

## Troubleshooting

- **Logs:** `nrwide.log` and `nrwide_launcher.log` are in `%LOCALAPPDATA%\nrwide`. `nrwide.log` lists every patch as
  `applied`, or `skipped` if a game update moved the code (the mod never writes bytes it hasn't verified first).
- **Black bars in co-op mode:** the mod joins slightly after the game starts there. Switch window mode once in Graphics.
- **The mod doesn't load:** Windows 11 *Smart App Control* blocks unsigned DLLs. The installer warns you if it's on.
- **Odd animations or physics at very high FPS:** set `fps_limit` to around 165.
- **Cutscenes and loading screens:** they're authored for 16:9, so the edges may show unfinished scenery.

## How it works

- `nrwide_launcher.exe` starts `nightreign.exe` suspended, injects `nrwide.dll`, then resumes it. In co-op mode it starts
  Seamless Co-op's own launcher instead, waits for `nrsc.dll`, then injects. `steam_appid.txt` lets the exe start
  without Steam relaunching it through EAC.
- `nrwide.dll` finds each patch site by byte pattern (no hardcoded addresses) and checks the expected bytes before writing:
  - **aspect-ratio clamp:** a `je` becomes `jmp`;
  - **frame-time target:** 1/60 s becomes 1/limit;
  - **fullscreen 60 Hz lock:** cleared;
  - **FOV getter:** redirected to a small stub that adds the saved offset.

  A watchdog re-applies patches if anything reverts them, and F7/F8 are read only while the game window has focus.
- The installer (`kit\data\setup\install.ps1`) uses a reusable terminal UI module, `kit\data\setup\tui.ps1`
  (Windows PowerShell 5.1, 24-bit colour, plain-text fallback).

Tested patterns: game version **1.3.3.0**.

## Build

Requirements: Windows, Visual Studio 2022 Build Tools (C++).

```bat
build.bat      :: builds bin\nrwide.dll, bin\nrwide_launcher.exe
package.bat    :: builds, then makes dist\widereign-mod.zip (Install.bat + Uninstall.bat + data\)
```

`build.bat` expects the Build Tools at the default install path; edit the `vcvars64.bat` line if yours differ.

`tools\preview.ps1` opens a live preview of the installer UI. It reloads when `tui.ps1` is saved; keys 1-5 switch
screens and T cycles colour themes. The installer's group version and colour theme are set in `kit\data\setup\kit.ini`.

Seamless Co-op is **not** bundled: its author doesn't allow re-uploading it. The installer sends each player to its
Nexus page instead.

## Credits

- The patch sites were first found by the Elden Ring / Nightreign modding community:
  [uberhalit](https://github.com/uberhalit/EldenRingFpsUnlockAndMore),
  [techiew](https://github.com/techiew/EldenRingMods),
  [Loukious](https://github.com/Loukious/NightreignUnlockTheFps) (FPS and FOV),
  [kotn3l](https://github.com/kotn3l/NightreignMods) and
  [adam-gdovin](https://github.com/adam-gdovin/nightreign-ultrawidefix) (ultrawide).
  WideReign's code is its own; it reuses their findings (byte patterns), not their source.
- [Seamless Co-op](https://www.nexusmods.com/eldenringnightreign/mods/3) by LukeYui. It's downloaded separately from Nexus Mods.

## License

[The Unlicense](LICENSE): public domain. Do anything you like with it. ELDEN RING NIGHTREIGN and related names are
trademarks of their respective owners.
