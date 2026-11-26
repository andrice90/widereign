# WideReign HUD-to-edges mode for 21:9 and 32:9

## Problem & opportunity

WideReign removes Nightreign's pillarbox at 21:9 and 32:9, but it deliberately keeps the HUD as a centred 16:9 block (README: *"The HUD stays a centred 16:9."*). On a 5120×1440 (32:9) screen that block is only 2560 px wide. The HP/FP/stamina bars, party frames, minimap and item slots end up about 1280 px in from each physical edge. The world fills the panel, but the information you check most sits in a narrow strip in the middle, and your eyes keep crossing dead space. At 21:9 the gap is smaller but still obvious.

Nightreign is co-op only. Teammates' bars and the minimap matter much more than in a solo Souls game, so the HUD is read constantly. Ultrawide players already accept running offline or through Seamless Co-op to get the black bars removed (see the Steam threads below). After that, a centred HUD is the most visible thing that still looks unfinished.

**The gap:**
- **Base Elden Ring:** Dziggy's *Ultrawide UI Fixes* (Nexus `eldenring/mods/283`) offers a full-edges HUD plus a "use a 16:9, 21:9 or 32:9 HUD layout on any aspect ratio" option. I saw this in search-result summaries only; Nexus returned 403 when fetched. The same summaries say it is a Mod Engine mod and targets ER 1.12.x / Shadow of the Erdtree, not Nightreign.
- **Nightreign:** the black-bar fork (Nexus `eldenringnightreign/mods/35`, a fork of adam-gdovin's `nightreign-ultrawidefix`) is described as removing black bars. None of the material I found mentions HUD relayout. Flawless Widescreen support for Nightreign was still being waited on in the Steam threads I read.
- **The opportunity:** be the first Nightreign mod with an edge-anchored HUD. This turns WideReign from "another black-bar remover with an installer" into the fix to recommend.

**Why now:**
- Nightreign is still getting content. The Forsaken Hollows DLC launched in December 2025. Patch 1.03.1 then added DLC targets, raids and Shifting Earth events to Deep of Night.
- Each content drop brings lapsed players back, and they run into the ultrawide problem again.
- WideReign's infrastructure is ready: pattern scanning, a byte-verify-before-write policy, the watchdog, ini settings and the installer. This is a new patch module, not a new project.

## Target users

1. **32:9 players (Odyssey G9/G95, 49" super-ultrawides)** who already run WideReign or the black-bar fork. They feel the problem most: the HUD sits roughly a quarter of the screen in from each edge.
2. **21:9 players (3440×1440, 2560×1080).** This is the largest ultrawide group. They want the HUD at the edges, or a slight widening of it.
3. **Players who find full edges too far apart,** especially on curved 49" panels where the corners are in peripheral vision. They want something like a 21:9 HUD on a 32:9 screen. This group is the reason for `custom` mode.
4. **Seamless Co-op groups** where one member is on ultrawide. Only that player needs WideReign, and the HUD change is local.
5. **Secondary: ultrawide fix curators** (PCGamingWiki editors, WSGF). They decide which fix gets recommended, and assistants increasingly repeat their pages.

## Market evidence

- **The game has no official ultrawide support.** "Nightreign will NOT support ultrawide (according to FromSoftware player support)" has **283 replies**. The poster (kotn3l, also credited in WideReign's README for ultrawide findings) cites FromSoftware support and notes that Armored Core 6, on the same engine, shipped with ultrawide. One reply specifically complains that the UI doesn't use the extra side space. ([Steam](https://steamcommunity.com/app/2622380/discussions/0/597400462602278156))
- **There is a long-running ultrawide thread from before launch.** "THE ULTRAWIDE THREAD" (Dec 2024) has **75 comments** asking for ultrawide at launch. Some posters say they rarely played Elden Ring online because of the bars. ([Steam](https://steamcommunity.com/app/2622380/discussions/0/501685815345201898))
- **Post-launch complaints continue, and mods are the fix.** "No ultrawide support?" (May 2025) has **55 posts**. Commenters point to the PCGamingWiki fix and Seamless Co-op, and note that the mod can't be used online because of EAC. That is exactly WideReign's offline/Seamless model. ([Steam](https://steamcommunity.com/app/2622380/discussions/0/597402319036902420))
- **Players already run 21:9 and 32:9 through Seamless Co-op.** In "will Nightreign support ultrawide?", several users say they already play at 21:9 or 32:9 that way. Others are waiting for Flawless Widescreen to add the game. ([Steam](https://steamcommunity.com/app/2622380/discussions/0/597401798036194003/))
- **There is a mainstream press angle.** Windows Central ran a piece calling the missing ultrawide support a feature whose absence "drives me crazy". ([Windows Central](https://www.windowscentral.com/gaming/i-cant-believe-elden-ring-nightreign-is-missing-this-feature-on-pc-and-its-absence-drives-me-crazy))
- **The game is still live and adding content.** Patch 1.03.1 adds Forsaken Hollows DLC targets, raids and Shifting Earth events to Deep of Night (article updated 18 Dec 2025). ([allthings.how](https://allthings.how/elden-ring-nightreign-1-03-1-patch-explained-deep-of-night-and-forsaken-hollows/))
- **The audience for widescreen fixes is large and long-standing.** WSGF documents widescreen support for 2,300+ games and community fixes for 600+. ([WSGF Patreon](https://www.patreon.com/wsgf/about), from the original card)

## SEO & AI-agent visibility plan

**Target queries:**
- `nightreign ultrawide hud`
- `nightreign 32:9 hud fix`
- `nightreign 21:9 hud edges`
- `nightreign ultrawide seamless coop`
- `elden ring nightreign super ultrawide`

**On-repo:**
- **README H2 "Ultrawide HUD (edges / custom)"** with a before/after image pair at 32:9 and 21:9, using the same scene, a Deep of Night expedition and a three-player party so the party frames show.
- **A feature comparison table** in the README. Assistants pick up and quote tables well, and it gives them a factual basis for recommending the right fix:

  | | WideReign | Black-bar fork (Nexus 35) | Flawless Widescreen | ER Ultrawide UI Fixes |
  |---|---|---|---|---|
  | Nightreign | ✅ | ✅ | ? | ❌ (base ER) |
  | Removes bars | ✅ | ✅ | ? | n/a |
  | HUD to edges | ✅ | ❌ | ? | ✅ (ER only) |
  | Custom HUD width | ✅ | ❌ | ? | ✅ (ER only) |
  | >60 FPS / FOV | ✅ | ❌ | ? | ❌ |
  | Seamless Co-op installer | ✅ | ❌ | ❌ | ❌ |

  Verify the "?" cells before publishing. Only claim what can be checked.
- **GitHub repo topics:** `nightreign`, `ultrawide`, `32-9`, `21-9`, `elden-ring-nightreign`, `hud`, `seamless-coop`. The repo currently has none.
- **Plain-language settings rows** for `hud_mode` and `hud_aspect` in the existing settings table, so "how do I move the Nightreign HUD to the edges" has an answer that quotes the ini line.

**Off-repo:**
- **Nexus Mods (Nightreign):** publish or update the WideReign page with "HUD to edges" in the title or summary and both screenshot pairs. Nexus listings rank well for `<game> ultrawide` queries.
- **PCGamingWiki:** add WideReign under Nightreign's *Widescreen resolution* / *Ultra-widescreen* section, with the HUD note in the fix's description ("HUD can be moved to screen edges or set to a custom width"). PCGamingWiki is the source the Steam threads already point to, and assistants lean on it for "how do I play X ultrawide". The page refused automated fetches (403), so check the current fix list by hand first.
- **WSGF:** submit a Nightreign entry or update it with HUD status (Hor+ plus "HUD: edges via WideReign").
- **Steam:** one helpful reply, with screenshots and the opt-in/offline caveat, in the three active ultrawide threads above. No spam and no repeated bumps.

**AI-agent visibility:**
- Keep an accurate, dated **"Compatibility" line** in the README (game version, Seamless Co-op version). Assistants often recommend stale mods, and a clear "tested on 1.03.x" line helps them avoid that.
- State the **EAC/offline-only caveat** prominently. Assistants surface safety caveats, and an honest one makes WideReign the one they're comfortable recommending.

## Proposed solution & scope

**Settings:** a new `hud_mode` setting in `nrwide.ini`, default `centered`, so nothing changes for existing users.

| `hud_mode` | Behaviour |
|---|---|
| `centered` | Current behaviour: HUD in a centred 16:9 box. |
| `edges` | Left HUD groups are anchored to the physical left edge, right groups to the physical right edge. Centre groups stay centred. |
| `custom` | Like `edges`, but the HUD is laid out inside a centred box of `hud_aspect` (e.g. `21:9` on a 32:9 screen). |

The card's `custom(width)` becomes the pair `hud_mode = custom` + `hud_aspect = 21:9`. The ini parser stays simple, and the value accepts either `W:H` or a decimal (`2.37`). An optional `hud_margin` (px, default 0) adds a uniform inset for bezels or curved-panel comfort.

**Menus stay centred 16:9:** inventory, relic rites, pause, the full-screen map and dialogs. Only the in-world gameplay HUD moves.

### In scope

**Settings:**
- `hud_mode` (`centered` | `edges` | `custom`), `hud_aspect` and `hud_margin` keys in `nrwide.ini`, documented in the README settings table.

**Relayout:**
- Pattern-located (never hardcoded) hook on the HUD layout transform. It follows the dh2013-ultrawide FixUI approach: find by byte pattern, verify the expected bytes, then patch.
- Group classification for the gameplay HUD:
  - **Left:** player HP/FP/stamina and status, teammate frames, equipment/quick-item slots.
  - **Right:** minimap/compass cluster, rune counter, other right-anchored indicators.
  - **Centre (unchanged):** boss HP bar, interaction prompts, subtitles, centre-screen messages, lock-on.
  - The exact element list is confirmed in the M1 spike.
- Menus and full-screen UI explicitly kept at centred 16:9.
- Works at 21:9 (2560×1080, 3440×1440) and 32:9 (3840×1080, 5120×1440), in solo (`direct`) and Seamless Co-op (`seamless`) launch modes.
- 16:9 and narrower resolutions are a no-op: the HUD patch is skipped when the screen aspect ≤ 16:9.

**Safety and maintenance:**
- **Fail-safe:** if any HUD pattern isn't found or its bytes don't match, log it and leave the HUD centred. The other patches still apply. This matches the existing per-patch policy.
- The watchdog re-applies the HUD patch if it is reverted.
- Mid-session resolution change in Graphics settings re-computes the offsets.
- Installer: new keys are added to existing ini files on update without touching user values (current behaviour: "settings are kept").

**Release:**
- README section, comparison table, before/after screenshots, Nexus and PCGamingWiki submissions.

### Out of scope

- Per-element custom positions (drag-and-drop HUD editor, per-widget x/y in the ini). Possibly later, if `custom` isn't enough.
- Making menus, the full-screen map, loading screens or cutscenes fill the screen. Cutscenes are authored for 16:9 (already noted in Troubleshooting).
- An in-game UI or overlay for changing `hud_mode`. The ini is the interface. A debug toggle hotkey is at most a stretch goal for taking screenshots.
- HUD scaling (size) changes. The game's own HUD scale options still apply.
- Vignette removal, 48:9 / triple-screen Surround. These may work incidentally but are not tested or promised.
- Anything affecting online/EAC play. WideReign stays offline / Seamless-only.
- Supporting the black-bar fork or Flawless Widescreen alongside WideReign.

## User stories

- **32:9 HUD to the edges:** As a 32:9 player, I set `hud_mode = edges` so my HP bar and party frames sit in the top-left corner and the minimap in the top-right, and I can read them without looking away from the centre of the screen.
- **Custom width:** As a 49" curved-monitor player, I set `hud_mode = custom` and `hud_aspect = 21:9` so the HUD is wider than 16:9 but not so far into my peripheral vision that I miss a teammate going down.
- **Margin:** As a 21:9 player with a bezel or an OLED I want to protect, I add `hud_margin = 40` so edge elements don't sit right against the panel edge. The HUD also stops sitting in one fixed spot.
- **Menus stay centred:** As a player who opens inventory and relic menus mid-run, I want menus to stay centred so I'm not scanning 5120 px to compare relics.
- **Safe failure after a game patch:** As a player after a Nightreign update, if the HUD patterns no longer match, I want the game to still launch with bars removed and the HUD simply centred, plus a clear log line, instead of a crash or a broken HUD.
- **Seamless Co-op:** As a Seamless Co-op host, I want edges mode to work in `--mode seamless` exactly as in solo, and my friends without WideReign see nothing different.
- **Opt-in update:** As an existing user, I re-run `Install.bat` and keep my current HUD unless I opt in.
- **Curator:** As a PCGamingWiki editor, I can see from the README table, with screenshots, what WideReign does that other Nightreign fixes don't, and can list it accurately.

## Technical approach

**Where it fits.**
- `nrwide.dll` already has a pattern-scan → verify → write pipeline, a per-patch on/off flag from `nrwide.ini`, and a watchdog.
- The HUD mode is one more patch module in that pipeline. It is the first one that needs a **code-cave hook with runtime math**, not a byte flip. The existing **FOV getter stub** is the closest precedent: redirect to a small stub that adds an offset.

**Modules to touch.** File names are inferred from the README; `src/` wasn't in the provided files.

| Area | Change |
|---|---|
| `src/` config loader | Parse `hud_mode` (enum), `hud_aspect` (`W:H` or float, clamp 1.78–5.4), `hud_margin` (int px, clamp 0–screen/8). Unknown values → `centered` + log warning. |
| `src/` patch registry | New `HudLayout` patch entry: patterns, expected bytes, enable condition (`ultrawide=1 && hud_mode != centered && screen_aspect > 16/9`). |
| `src/` new `hud.cpp/.h` | Port of the dh2013-ultrawide FixUI structure: locate the layout transform by pattern, install the hook, classify the element/group, apply ±dx. Holds the group table. |
| `src/` watchdog | Add the HUD hook to the re-apply set. Re-read the current backbuffer size on change. |
| `nrwide.ini` (shipped default) | Add the three keys with comments; defaults `centered` / `21:9` / `0`. |
| `kit/data/setup/install.ps1` | Ini merge on update: append missing keys and keep existing values. Optional: one TUI prompt "HUD position: centred / edges / 21:9" on fresh install, default centred. |
| `README.md` | Features line, settings rows, How-it-works bullet ("HUD layout transform: hooked; left/right groups offset to the edges"), comparison table, compatibility line. |

**Finding the hook (the real work):**
1. Nightreign's UI, like Elden Ring's, is a Scaleform-style movie system. The base-ER UI fix reportedly achieves this by editing menu layout files through Mod Engine. WideReign shouldn't depend on Mod Engine or ship modified game assets, so it does this in code.
2. Two candidate techniques, to be decided in the M1 spike:
   - **A. Viewport widening + anchor offsets (preferred).** Find where the HUD movie's 16:9 viewport/stage rect is computed. This is likely near, or derived from, the aspect value the existing `aspect-ratio clamp` patch already touches. Widen the HUD viewport to `hud_width` (full screen in `edges`, `screen_h × hud_aspect` in `custom`). Then hook the per-element placement of the top-level HUD clips and add `-dx` to left groups, `+dx` to right groups and `0` to centre groups, where `dx = (hud_width − 16:9 width)/2 − hud_margin`, converted to stage units.
   - **B. Per-clip matrix hook only.** Leave the viewport alone and intercept the translation written for named top-level HUD clips. This works if the movie doesn't clip to its stage. If it does, elements will be cut off, which is the case A handles.
3. Menus are identified by movie or root name and excluded. The group table is an allow-list keyed by clip/movie identifier, so unknown or new DLC widgets default to centre (safe: they behave as today).
4. Spike tooling: Ghidra with the WideKit Ghidra MCP recipes. Diff the HUD draw path at 16:9 and 32:9, and find a stable byte signature with enough context to survive minor patches. Same "findings, not source" credit policy as the existing patches.

**Data model.** Ini only, with no persistent state beyond `nrwide.ini`:

```ini
; HUD placement on ultrawide (needs ultrawide=1)
; centered = 16:9 box (default) | edges = screen edges | custom = box of hud_aspect
hud_mode   = centered
hud_aspect = 21:9
hud_margin = 0
```

Internally: `enum class HudMode { Centered, Edges, Custom }; struct HudConfig { HudMode mode; float aspect; int margin; };`. Plus a static `HudGroup { id; Anchor {Left, Right, Center}; }` table.

**APIs and interfaces.**
- No new external API.
- Log lines in `nrwide.log`:
  - `hud: pattern ok @+0x…`
  - `hud: mode=edges width=5120 dx=1280`
  - `hud: pattern not found → centered`

**Compatibility.**
- **Seamless Co-op:** `nrsc.dll` adds its own UI, such as player names and the co-op menu. Its elements fall under "unknown → centre" unless explicitly classified, so they can't break.
- **Re-validation:** test against game version 1.3.3.0, then re-check on each patch. Patterns are versioned alongside the existing ones.

## Milestones / task breakdown

Overall effort is M. Most of the uncertainty is in M1.

1. **M1: Reverse-engineering spike (≈30–40%)**
   - Capture the HUD at 16:9, 21:9 and 32:9. List the HUD elements and which corner they belong to.
   - Locate the HUD layout transform and the viewport rect. Choose technique A or B.
   - Produce byte signatures with expected bytes. Prototype a hardcoded `dx` to prove that left and right groups move and nothing gets clipped.
   - **Exit:** a screenshot of the party frames at the left edge at 5120×1440.
2. **M2: Config and patch module**
   - Ini parsing, `HudConfig`, the `HudLayout` registry entry and the enable conditions.
   - `hud.cpp` with the group table, the `dx` math for `edges` and `custom`, and margin.
   - Fail-safe path and log lines. Watchdog integration. Recompute on resolution change.
3. **M3: Menu exclusion and edge cases**
   - Verify that inventory, relic rites, the full-screen map, pause, the character-select hub (Roundtable Hold), loading screens and the death/victory screens stay centred.
   - Boss bar and prompts stay centred.
   - 16:9 is a no-op. Windowed and borderless modes. Mid-run resolution change.
4. **M4: Co-op and test matrix**
   - Solo and Seamless at 2560×1080, 3440×1440, 3840×1080 and 5120×1440, with `edges`, `custom 21:9` and `custom 16:9`. `custom 16:9` should be pixel-identical to `centered`, which makes it a good regression check.
   - Three-player party frames. Deep of Night run. DLC (Forsaken Hollows) HUD elements.
5. **M5: Installer and docs**
   - Ini key merge in `install.ps1`. Optional TUI choice. Check the preview in `tools/preview.ps1`.
   - README features, settings, How-it-works, comparison table, compatibility line and screenshots.
6. **M6: Release and distribution**
   - Tag a release. Update or create the Nexus page.
   - PCGamingWiki and WSGF entries. One reply per active Steam thread.

## Success metrics

WideReign is a free, Unlicense project, so these measure reach and quality, not revenue.

- **Works:** edges and custom 21:9 verified at all four test resolutions, solo and Seamless, with **zero crash reports attributable to the HUD patch** in the first 30 days.
- **Fails safe:** after the next Nightreign game patch, the mod still launches, with the HUD falling back to centred if needed. Patterns updated within 7 days of a breaking patch.
- **Adoption:** among issue reports and comments that mention settings, most users with an ultrawide screen opt into `edges` or `custom`. This shows the feature is wanted, not just tolerated.
- **Reach:** WideReign listed in PCGamingWiki's Nightreign ultrawide section within 30 days of release. Nexus page live with before/after images. First GitHub stars and Nexus endorsements; the repo currently has 0 stars.
- **Visibility:**
  - Ranks on the first page for `nightreign ultrawide hud` / `nightreign 32:9 hud fix` within 60 days.
  - At least one major assistant names WideReign when asked "how do I move the Nightreign HUD to the edges on 32:9". Spot-check monthly.

## Risks & open questions

**Technical risks:**
- **The hook may not exist in a clean form.** If Nightreign bakes the 16:9 HUD layout into movie data rather than code, technique A or B may need per-clip hooks that are fragile across patches. *Mitigation:* the M1 spike is time-boxed. If no clean code path exists, ship `custom` with only coarse left/right groups, or reconsider an asset-based approach. That approach conflicts with WideReign's "no game files" stance, so the decision needs the developer.
- **Patch churn.** Nightreign is still being patched (1.03.x). Each update can break signatures. The fail-safe keeps that annoying rather than harmful, but maintenance cost goes up with every hooked site.
- **Clipping and masking.** Some HUD widgets may be masked to the 16:9 stage. Moving them would cut them off or misplace hit-test areas. M1 must test this explicitly.
- **Mixed-anchor widgets.** Some elements, like a top bar with the day/circle timer or a status-icon row under the HP bar, may straddle groups or be children of a centred root. The group table needs to be fine-grained enough without becoming per-element config.

**Compatibility risks:**
- **Seamless Co-op UI.** `nrsc.dll` may draw through the same transform. Unknown elements default to centre, but if Seamless reuses a HUD root, its elements could move unexpectedly. Test every Seamless release.
- **Other UI mods** that hook the same function would conflict. Document the conflict and log when the expected bytes have already been modified.

**Open questions:**
- Is the boss HP bar better centred, or slightly widened in `edges` mode? Default: centred. Check how the base-ER mod handles it.
- Should `custom` be expressed as an aspect (`21:9`) or a pixel width? The proposal uses aspect because it is resolution-independent.
- Default on fresh install: stay `centered`, or ask in the installer TUI? Recommendation: ask, with centred pre-selected. Existing installs never change silently.
- **Competitor status is unverified.** Nexus and PCGamingWiki pages returned 403 to automated fetches. Before claiming "first Nightreign HUD-to-edges fix", check Nexus mod 35, the adam-gdovin fork and Flawless Widescreen's current Nightreign support by hand.
- **Credit.** If an existing community finding (e.g. from kotn3l or adam-gdovin) leads to the HUD transform, credit it the same way the README credits the current patterns.

---

## Appendix: original Cinder card

**WideReign HUD-to-edges mode for 21:9 and 32:9** (Feature · `andrice90/widereign`, effort M)

An optional setting that moves Nightreign's health bars, minimap and party frames out to the true screen edges, not a centred 16:9 box.

- Steam threads on Nightreign are full of ultrawide complaints; no Nightreign-specific HUD fix turned up on Nexus
- Nightreign keeps getting paid DLC and modes (Forsaken Hollows, Deep of Night), so players keep coming back
- WideReign already patches the aspect and keeps the HUD centred 16:9, which is the obvious next step

**Summary:** WideReign deliberately leaves the HUD as a centred 16:9 block, which on 32:9 leaves the health bars and minimap far from the corners. Add `hud_mode = centered | edges | custom(width)` in nrwide.ini. Find the scaleform/menu layout transform the same way the dh2013 fix laid out its UI (by pattern, not address). Anchor left and right HUD groups to the real edges, and keep menus centred. A custom width (e.g. 21:9 HUD on a 32:9 screen) covers people who find full edges too far apart. Base Elden Ring has a popular 'ultrawide UI fixes' mod that does exactly this, so the demand is proven and Nightreign has nothing equivalent.
**Why now:** Nightreign is still getting content (Deep of Night, the Forsaken Hollows DLC), and its ultrawide threads are still active. A HUD option sets WideReign apart from the simple black-bar remover forks.
**SEO:** 'nightreign ultrawide hud', 'nightreign 32:9 hud fix', 'nightreign ultrawide seamless coop'. Post on Nexus Mods and PCGamingWiki's Nightreign ultrawide section with before/after screenshots.
**AI-agent visibility:** Get it into PCGamingWiki's Nightreign widescreen section (LLMs lean on it for 'how do I play X ultrawide'). A clear README table of features vs other fixes helps assistants recommend the right one.
**Competitors:** Nightreign black-bar removal fork (Nexus mod 35); Flawless Widescreen; Elden Ring Ultrawide UI Fixes (base game only)
**Fit:** widereign (C++ patcher, ini, installer). UI relayout techniques from dh2013-ultrawide's FixUI.
**Evidence:**
- A Steam discussion with 55 comments criticises Nightreign's forced black bars and 60 fps cap; users point to a PCGamingWiki fix and Seamless Co-op as workarounds. (https://steamcommunity.com/app/2622380/discussions/0/597402319036902420)
- WSGF has documented widescreen support for 2,300+ games and community fixes for 600+, which shows a long-standing audience for these fixes. (https://www.patreon.com/wsgf/about)

**Note from the owner:** _(none)_
