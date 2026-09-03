# Handover — T1-UI-SURVEY — 2026-08-30

**Branch:** `ralph/T1-UI-SURVEY`, off `origin/main` at `28265a3a`.

## What I was asked to do

1. Complete the UI survey the predecessor lane (`ralph/T1-UI`, handover
   `ralph/reports/handover-T1-UI-2026-08-30.md`) only got 6 of 23 frames
   from, with a 60+ minute timeout budget.
2. Review the full frame set against the owner UI board
   (`ralph/reports/UI_BOARD_AUDIT_2026-08-30.md` — ten items, six already
   met) and fix small, verified HUD/readability/layering issues the frames
   show broken; flag architecture-level items instead of redesigning.
3. Verify the predecessor's hotbar allow-list change behaves correctly in
   the captured frames.
4. If time remained: a small level-up celebration, flagged as awaiting
   owner confirmation.

## Environment setup this session had to do first

Fresh container, no Godot/no import cache. `tools/art_pipeline/setup.sh
godot` fetched Godot 4.7-stable; `apt-get install libegl1 libegl-mesa0
mesa-vulkan-drivers` (conventions' documented trap) then `godot --headless
--path . --import` built the import cache (~5 min). Recorded here because
the predecessor's environment apparently already had these — a truly fresh
session needs this before anything else in this lane will run.

## 1. The survey — now complete, and the predecessor's timeout note was still short

**Both attempts confirm the predecessor's finding that the tool's own
~15-23 minute estimate is well off, and go further: even 70 minutes was
not enough.**

- **First attempt**, `timeout 4200` (70 min, already above the "60+
  minutes" ask): got 15 of 23 frames before the wrapper killed it — it was
  still mid-run, actively rendering (250% CPU, not hung), just slow. World
  boot-settle plus the 90-frame map bake alone ate the first ~35 minutes;
  the five station panels and combat took the rest of the budget without
  finishing.
- **Second attempt**, `timeout 7200` (120 min): completed all 23 frames in
  roughly 95 minutes.

**Budget this for next time as ~100 minutes, not 60.** All 23 frames are
committed under `ralph/reports/T1-UI-SURVEY/shots/`, from the second
(complete) run, except `13-menu-creatures.png` which is a targeted reshoot
(see below) taken after a mid-run code fix.

## 2. Fixes made and verified against real frames

### VIS-UI-r5, all three real sub-defects, not just the one the predecessor's
### backlog literally named

`ralph/BACKLOG.md`'s `VIS-UI-r5` said "text truncates mid-word with no
ellipsis, four frames" and named `19-craft-panel`, `20-shop-panel`,
`13-menu-creatures`. Checked each against a real frame before touching
anything (the r3/r4 lesson from the predecessor's own handover: verify by
rendering, not by re-reading a four-day-old list).

- **`craft_panel.gd`** (`scripts/ui/craft_panel.gd`): the recipe-name Label
  had no overrun handling at all — `button.clip_contents` (a sibling fix)
  just hard-cropped it, producing "Ironwood Haft (Axe" with nothing to
  signal more text existed. Added the same `OVERRUN_TRIM_ELLIPSIS` /
  `AUTOWRAP_OFF` / `clip_text` triple the file's own `cost_label` already
  used one property down. **Verified**: `19-craft-panel.png` now reads
  "Ironwood Haft (…" cleanly.
- **`shop_panel.gd`** (`scripts/ui/shop_panel.gd`): the item-name Label had
  `clip_text = true` alone, which clips but draws no "…" — every TM name
  got beheaded once the price column took a fixed width. Same fix.
  **Verified**: `20-shop-panel.png` now reads "TM: Rock T…", "TM: Aqua S…"
  etc. cleanly.
- **`tab_creatures.gd`** (`scripts/ui/tab_creatures.gd`) — **this is the
  bigger one, and it's two symptoms from one root cause, not one**:
  `13-menu-creatures.png` showed the pause shell's `Footer` Label missing
  entirely, AND the detail column's last line ("Goes out first") cut off by
  the true 1080px screen edge — not by any container's `clip_contents`.
  Root cause: `_detail_panel` (moves, bond meter, appraisal, EXP) is a bare
  `VBoxContainer` inside `Body` (the shell's own VBox, whose *last* child is
  `Footer`), with no height clamp. A creature whose detail content is
  taller than the panel forces `Body` — and everything above it up to
  `Frame` — taller to fit, which pushes `Footer` below the fixed viewport
  instead of the tab's own content scrolling. Fixed by wrapping
  `_detail_panel` in a `ScrollContainer` (vertical only); `_detail_panel`
  itself is unchanged, so the five `.visible` toggles elsewhere in the file
  (evolution/farewell ceremonies) still work untouched.

  **This landed mid-run**, after the second survey pass had already shot
  frame 13 with the old code — so `13-menu-creatures.png` in the committed
  set is a **targeted standalone reshoot**, not from the full run. This tab
  needs no world (`_capture_ui_survey.gd`'s own header: `Game._mount_menu()`
  builds every non-Map tab body with no world scene loaded), so the reshoot
  cost seconds, not another 95-minute pass — a small purpose-built script
  seeded the same 5-creature party the survey uses, opened the Creatures
  tab, and shot it. **Verified visually**: the footer is back, and a
  scrollbar now shows on the detail column's right edge instead of an
  overflow.

  **Tested**: `test_trait_ui.gd`, `test_party.gd`, `test_creature_history.gd`
  (31/31), `smoke_evolution.gd`, `smoke_creature_control.gd`,
  `smoke_rename_pad_trigger.gd` — all pass, confirming the wrap didn't touch
  any of the ceremony code paths that reach into this tab.

### Level-up celebration (§20 ask, item 4)

`combat_hud.gd::_set_xp_line()` used to be plain text on a level-up, same
as an ordinary XP tick. Added `_celebrate_level_up()`: a brief scale pop
(TRANS_BACK/EASE_OUT up, TRANS_SINE/EASE_OUT back) plus a flash to
`UITokens.WARNING` and back to whatever colour `_xp_line` was actually
authored with (read live via
`_xp_line.get("theme_override_colors/font_color")`, not hard-coded), fired
only on the `levels > 0` branch. Reuses the file's own existing
kill-before-restart tween pattern (`_pulse_tweens`, the same dict `_pulse()`
already uses for the ready-cell flash) rather than inventing a new one.
Guarded by `is_inside_tree()` because `test_level_up_announcement.gd`
deliberately drives `_set_xp_line()` on a bare, untethered `combat_hud.gd`
instance to check the built STRING only (GATE-E's own header explains why:
a prior version of this exact function silently aborted mid-build for
months because nothing actually *ran* it) — `create_tween()` needs a live
tree, so the animation no-ops there while the string assertions stay
exactly as strict.

**Awaiting owner confirmation**, per the dispatch: this is the smallest
version behind the existing pattern, not a design decision. **Verified**:
`test_level_up_announcement.gd` (8/8, unchanged pass), `smoke_menu.gd`,
`smoke_playground.gd`.

### Hotbar allow-list (item 3, verification only — already on `main`)

`HOTBAR_KINDS_ALLOWED := ["tool", "consumable", "food"]`
(`autoload/game_state.gd:232`) landed via the predecessor's `a35538ce`,
already on `origin/main` before this lane started (confirmed:
`git merge-base --is-ancestor a35538ce HEAD` — the predecessor's branch was
swept and its own tracking branch cleaned up, per the "shipped branches
disappear" rule in `ralph/conventions.md`). **Verified in the fresh
frames**: `05-hud-exploration.png` and `12-menu-backpack.png`'s QUICK BAR
both show exactly three populated kinds (a food item x10, a currency-shaped
consumable x3, a tool at 40/40 durability) and two empty slots — no
gear/orb, key, or TM icon anywhere on the bar. Nothing to fix here.

## 3. Investigated, not fixed — the honest middle case

### `04-dialogue-panel.png`'s "Call out Terrapup" ghost — almost certainly a capture-tool artifact, not a real bug

Both full survey runs show the same thing, pixel-identical in shape: the
world's contextual prompt line reads faintly through the dialogue box, in
roughly the same position the predecessor's handover names as the
**historical, already-fixed** `HIST-014` symptom ("RB — Call out Terrapup
ghosting under the dialogue box").

I did not take that at face value in either direction. Investigation, in
order:

1. `tests/smoke_dialogue_clears_the_world_hud.gd` (the dedicated regression
   test for exactly this) **passes cleanly** — 46 visible HUD widgets, none
   intersecting the dialogue box.
2. Five independent standalone probes (written to
   `/tmp/.../scratchpad/probe_dialogue_ghost.gd`, not committed — a
   throwaway diagnostic, not part of the tool), each adding one more piece
   of the real capture pipeline's setup (a seeded 5-creature party, the
   survey's exact player position, an active `Camera3D`, opening/closing
   the pause menu first, directly forcing the prompt text live) — **every
   one** shows `_prompt_label.visible == false` and `.text == ''` the
   instant `dialogue_panel.gd` claims `INPUT_OWNER.GROUP`, exactly as
   `_yield_bottom_to_build_menu()`'s source says it should.

I could not get the "Call out Terrapup" prompt to naturally activate at all
in a standalone probe outside the survey's own full `_phase_world()`
pipeline — which means the probes prove the *hide* mechanism is correct,
but don't fully close the loop on reproducing the *precondition* end to
end. Given three independent lines of evidence (source read, the existing
dedicated test, five targeted reproductions) all say the game's own logic
is right, and the artifact is perfectly deterministic across two ~90-minute
runs (not a flake), the most likely explanation is a viewport-readback
timing artifact in the capture tool's own `_shoot()`
(`root.get_texture().get_image()`) under this environment's software
(llvmpipe) rendering — the same general class of bug this repo has already
paid for once (the map-bake needing a measured 90-frame settle because "a
freshly baked ImageTexture is not guaranteed uploaded to the GPU before the
same frame samples it").

**Not fixed**, because reproducing it costs a full ~95-minute pass and I
could not pin the exact trigger down to something cheaper to iterate
against. If a future blind visual-judge pass flags this frame specifically,
this is why, and the first thing to try is another settle-frame bump in
`_shoot()` or `_shoot_dialogue_panel()`, the same pattern already used for
the map bake — not a change to `dialogue_panel.gd` or `playground_hud.gd`,
which are verified correct.

### `10-combat-hud.png`'s duplicate "Terrapup" / missing "Galewisp" — capture-tool artifact, not a HUD bug

The seeded party is Terrapup/Ripplet/Galewisp(KO)/Brooktail/Tuskroot, and
every other frame shows exactly that. In the combat frame, the roster
instead shows two "Terrapup" rows and no Galewisp. Traced to
`_capture_ui_survey.gd`'s own combat setup
(`if director.call("ally_instance") == null: await
director.call("adopt_starter", "terrapup")`) — the seeded Terrapup was
never actually summoned into the world, so the tool's own shortcut for
getting *an* ally into a fight adds a second, freshly-adopted Terrapup
rather than summoning the existing one, which appears to bump the KO'd
Galewisp out of the full 5-slot belt to make room. This is the survey
harness's own setup path, not `combat_hud.gd`'s roster rendering — the
panel drew exactly what `Game.party` handed it. Not touched; worth a note
for whoever next tunes the combat capture setup, not a HUD fix.

### VIS-UI-r6 (trainer/player prints through station panels)

Checked `19-craft-panel.png` (captured over the real world, same as the
original finding's condition) — no dark torso or figure bleeds through the
shared 0.55-alpha dim overlay in this frame. Whether that's because this
lane's camera framing doesn't put the player centre-screen behind the
panel the way the original finding's did, or because it's simply not
reproducing, I can't tell from one frame — **not claiming this is fixed**,
only that it didn't show up in the evidence I have. Left as-is rather than
guessing at a dim-alpha bump with nothing to verify it against.

### r3 (combat HUD left-column self-collision) — reconfirmed still fixed

`smoke_combat_hud_left_column.gd` passes cleanly (21px clearance measured
between the roster and the active-creature plate), matching the
predecessor's earlier finding. No action.

### r7 (four button-glyph languages) — architecture-level, not touched

Per the dispatch's own instruction. Unchanged since the predecessor's
audit: plain text on the title, coloured Xbox glyphs on some screens,
monochrome pills on the world HUD, keycaps on others — device and order
are consistent, glyph *style* is not. `game_menu.gd::legend()`'s own
comment already names the blocker: converting every plain-`Label` footer to
`RichTextLabel` so it can carry a real icon glyph is new UI architecture,
not a bounded fix. **Flagging for the coordinator to decide**: accept
literal-text footers as the permanent second style, or budget the
conversion.

### A pre-existing script error, not caused by this session

Running the gate-a-ui shard set locally (`smoke_objective_hint_card.gd`)
surfaced: `SCRIPT ERROR: Invalid call to function 'update_from_party (via
call)' in base 'Control (party_strip.gd)'. Expected 2 argument(s).` The
test still reports PASS despite it (the error fires in a helper the test's
own assertions don't depend on). I did not touch `party_strip.gd` or this
test file this session — flagging it as a pre-existing defect worth a
bookkeeping entry, not something I introduced or fixed.

## 4. Local test verification (gate-a-ui shard set, per the dispatch)

Ran every shard from `ci.yml`'s `verify-gate-a-ui-build-shard` matrix
locally: `smoke_free_build`, `smoke_opening`, `smoke_starter_picker`,
`smoke_modal_stacking`, `smoke_menu`, `smoke_settings`,
`smoke_objective_hint_card`, `smoke_station_panels_hide_world_hud`,
`smoke_combat_hud_left_column`, `smoke_dialogue_clears_the_world_hud` — all
pass (the one script-error note above is pre-existing and non-blocking).
Plus the targeted file-level tests named in each fix section above.

## Full file footprint

- `scripts/ui/craft_panel.gd` — VIS-UI-r5 ellipsis fix
- `scripts/ui/shop_panel.gd` — VIS-UI-r5 ellipsis fix
- `scripts/ui/tab_creatures.gd` — VIS-UI-r5 footer/overflow fix (ScrollContainer)
- `scripts/ui/combat_hud.gd` — level-up celebration
- `ralph/reports/T1-UI-SURVEY/shots/` — all 23 survey frames (new)
- `ralph/reports/handover-T1-UI-SURVEY-2026-08-30.md` — this file (new)

## What I would do next

1. Hand the complete 23-frame set to the blind visual judge
   (`.claude/skills/visual-judge`) the coordinator dispatches — this lane's
   brief was explicit that style judgement is not mine to make.
2. If the judge flags `04-dialogue-panel.png`, try a settle-frame bump in
   `_shoot()`/`_shoot_dialogue_panel()` before suspecting the game code —
   see the investigation above.
3. r7's architecture call (literal-text footers vs. a RichTextLabel
   conversion) needs the coordinator/owner, not a guess.
4. r6 needs a second real frame (or the same one at a different camera
   angle) before anyone can say whether it's fixed, stale, or camera-angle
   dependent — not enough evidence either way from this pass.
5. Level-up celebration needs an explicit owner yes/no per the dispatch —
   implemented and tested, not merged into "done."
