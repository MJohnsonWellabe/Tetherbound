# W11-ALPHA-PINS — alphas pin to the map at 300 m and stay pinned (CL-W1)

Branch: `ralph/W11-ALPHA-PINS-0904`
Closure-plan row: CL-W1. Owner directive D-0904B-1 with same-day amendment A-3.

This lane was started by an earlier session that hit a usage limit after pushing the
feature and a live smoke. This report is the finisher's: it verifies what was pushed,
trims the diff back to the lane's ownership list, runs the full unit suite the save-format
change requires, runs the named tests and smokes with independent red checks, captures the
acceptance frame, and records the blind judge's verdict.

---

## 1. Files changed

`git diff --name-status origin/main...HEAD` — 13 files, all inside the brief's ownership
list and nothing else:

| Status | File | Why |
|---|---|---|
| M | `autoload/map_state.gd` | owns the pinned set (`pin_alpha`/`unpin_alpha`/`is_alpha_pinned`/`alpha_pins`), its save/load pair, and the `display_name` field dynamic markers gained |
| M | `scripts/save/save_game.gd` | `VERSION` 16 → 17, the `alpha_pins` top-level key, `_migrate_v16` |
| M | `scripts/ui/minimap.gd` | draws an alpha marker as a red chevron instead of a camp dot |
| M | `scripts/ui/tab_map.gd` | full map: the coloured plate, the species-name pass, the one legend row |
| M | `scripts/world/playground_world.gd` | one `add_child(ALPHA_PINS.new())` line, nothing else |
| A | `scripts/world/alpha_pins.gd` (+ `.uid`) | the proximity and clearing logic, kept out of `encounter_director.gd` |
| A | `data/config/map.json` | `radius_m` / `check_interval_s` / `icon` / `first_pin_message` |
| A | `assets/ui/icons/map/alpha.png` (+ `.import`) | the pin glyph |
| A | `tools/gen_alpha_pin_icon.py` | generates that glyph |
| A | `tests/test_alpha_pins.gd` | the logic, persistence and clearing half |
| A | `tests/smoke_alpha_pins.gd` | the live half — a real node, a real clock, a real save file |
| A | `tools/_capture_alpha_pin_map.gd` | the acceptance frame (added by this finisher) |

### Diff hygiene — 58 files removed

The feature commit was made after a full `godot --import` and had swept up 58 files that
belong to no part of this lane: `.import` sidecars **and the extracted textures** for other
lanes' GLB assets (candy/mushroom/potion/revive pickups, the riding saddle, the south
bridge gate — ~18 MB of PNG and JPG), plus `.uid` sidecars for fourteen other lanes' test
and tool scripts. Commit `730633db` removes all 58. The branch diff is now exactly the
table above.

`assets/ui/icons/map/alpha.png.import` and `scripts/world/alpha_pins.gd.uid` are **kept**:
every other icon in `assets/ui/icons/map/` and every other script in `scripts/world/` is
tracked with its sidecar on `main`, so dropping these two would be the inconsistency.

> **For the coordinator:** the removal is a normal commit, not a history rewrite (COMMON
> forbids force-push), so those ~18 MB of blobs still exist in this branch's *history* even
> though they are absent from its tip. A **squash merge** keeps them off `main` entirely.

---

## 2. What the player gets

Sixteen `alpha`/`elder` clusters are authored across `data/config/bands/*/spawns.json` and
were, before this, entirely unadvertised — a player could walk the whole corridor past
every one of them and never learn they were there.

Now:

* **They announce themselves.** Come within **300 m** of an authored alpha or elder cluster
  and it appears on both the minimap and the full map. On the minimap it is a red chevron —
  a different *shape*, not just a different colour, because colour alone does not survive
  being drawn small next to cream camp dots and white landmark circles. On the full map it
  is the only coloured plate on the screen, captioned with the name the creature's own
  nameplate will carry (**"Alpha Trailpup"**, **"Elder Mosshell"**), with one legend row
  reading *Alpha* so a red mark the player has never seen has a word for it.
* **The pin comes from the authored data, never a live body.** At 300 m the creature is
  usually not streamed in yet; a body-driven pin would appear only once the player could
  already *see* the alpha, which advertises nothing.
* **It survives quitting.** The pinned set is in the save (`VERSION 17`, top-level
  `alpha_pins`) and comes back on load, markers and labels included. This is the closure
  plan's own *fails if* — "a pin that survives only until the next load is worse than none."
* **It clears when you win.** Catching **or** beating the alpha (A-3) fires the same
  `wild_once_<order>` flag `encounter_director.gd` already fires, and the pin goes within
  half a second — including retroactively on load, if the flag fired in a session whose
  save predates the pin. A beaten alpha does not re-pin while the player stands next to it.
* **One line, once.** The first pin ever placed pushes *"An alpha is near — marked on your
  map."* through the normal world-message channel; the remaining fifteen do not repeat it.
  The one-shot is a progression flag, so it survives a save and a scene change.

**Amendment A-3, honoured as written.** The directive said "does not disappear until
caught"; A-3 amended it to *caught or beaten*, because a player whose five slots are full
cannot catch anything and a catch-only clear would leave a permanent pin they could do
nothing about. Both outcomes already fire one flag, so both clear the pin.

---

## 3. Tests and smokes

Godot 4.7-stable, installed per COMMON.md. Every command below was run in this container on
this branch's tip tree.

### The lane's own test

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_alpha_pins.gd
→ 24 tests, 154 assertions, 0 failed
```

**Seen red, independently of the authoring session's own claims.** Two behaviours were
broken by hand, watched fail for the right reason, and restored:

| Broken | Result |
|---|---|
| `map_state.gd::unpin_alpha()` made a no-op (the erase and `remove_dynamic_marker` deleted) | **3 failed** — `test_the_pin_clears_when_the_alphas_once_flag_fires`, `test_clearing_one_alpha_leaves_its_neighbours_pinned`, `test_a_pin_whose_flag_fired_before_the_save_is_pruned_on_load` |
| `save_game.gd`'s `"alpha_pins"` write replaced with a literal `[]` (the closure plan's *fails if*, reproduced) | **3 failed** — `test_a_pin_survives_a_save_and_load`, `test_the_save_file_carries_the_pinned_set_at_its_top_level`, `test_a_pin_whose_flag_fired_before_the_save_is_pruned_on_load` |

Restored and re-run: 24 / 154 / 0 again, and `git diff` clean.

### The live smoke — the acceptance sentence

```
godot --headless --path . --script tests/smoke_alpha_pins.gd
→ alpha pins: pinned at 275.0 m (radius 300 m, walked in from 550.0 m)
→ alpha pins: OK — a body walking in pins the Band 2 alpha inside 300 m, the pin is in
  the marker list both screens draw, it survives a real save/load, and beating it clears
  it and keeps it cleared.
→ exit 0; `^ERROR:` 0, `SCRIPT ERROR` 0
```

A real `CharacterBody3D` walks in from 550 m toward Band 2's order 2011 (trailpup, authored
centre `[-180, 0, 2250]`) on a real `SceneTree` clock, driving the real `AlphaPins` node's
own `_process`. It pins at 275 m — the boundary crossing, not a teleport onto the marker.
A real `SaveGame` write and read into a **discarded and rebuilt** `MapState` brings it back;
firing `wild_once_2011` clears it; it does not return on reload.

**Seen red:** `radius_m` dropped to `30.0` in `data/config/map.json` →
`alpha pins FAIL: the alpha pinned only at 0.0 m; the owner's directive is 300 m`.
Restored; `git diff -- data/config/map.json` empty.

### The other named tests and smokes

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_save_format.gd
→ 55 tests, 271 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=test_map_baker.gd
→ 7 tests, 13 assertions, 0 failed

godot --headless --path . --script tests/smoke_save_persistence.gd
→ PASS: exact pose, opening/starter, Tam gift, TM/key one-shots, and controls
  survived a real Meadows save/load
→ exit 0; `^ERROR:` 0, `SCRIPT ERROR` 0

godot --headless --path . --script tests/smoke_wild_streaming.gd
→ wild streaming: OK — distant clusters sleep, near ones tick, engaged/fainting/
  respawning are never touched, and a round trip changes nothing about a
  creature's identity.
→ exit 0; `^ERROR:` 0, `SCRIPT ERROR` 0
```

Both smokes ran clean: the known-benign error set did not grow — it stayed at **zero**
matches for `^ERROR:` and `SCRIPT ERROR` in either log.

### The FULL unit suite — required, because the save format changed

```
godot --headless --path . --script tests/run_tests.gd
→ 1837 tests, 3723851 assertions, 4 failed   (~26 min)
```

**All four failures are pre-existing on `main` and none is reachable from this diff.**

| Failing test | Why it is not this lane's |
|---|---|
| `test_item_icons.gd :: test_every_item_has_an_icon_field_whose_file_exists` | The red COMMON.md names at lane start: six missing candy/mushroom icons, owned by another lane. Explicitly not to be fixed here. |
| `test_item_icons.gd :: test_every_item_icon_loads_as_a_texture` | Same cause, same lane. |
| `test_scatter_perf_budget.gd :: test_playground_bake_is_committed_and_fresh` | See below. |
| `test_terrain_bake_freshness.gd :: test_playground_terrain_bake_is_committed_and_fresh` | See below. |

The two bake-freshness failures are **not** in COMMON.md's known-red list, so they are a
finding for the coordinator rather than an expected red. They are demonstrably not this
branch's: both assertions compare a manifest against a hash of a fixed input set —
`terrain_bake.gd::config_fingerprint()` reads `data/config/terrain_playground.json`, and
`scatter_bake.gd::config_fingerprint()` reads that plus `data/config/vegetation.json` plus
`data/config/bands/*/vegetation.json` — and **every one of those files, and both
`manifest.json` files, is byte-identical to `origin/main`** on this branch:

```
data/config/terrain_playground.json   main=00f5c76c  head=00f5c76c  SAME
data/config/vegetation.json           main=790b44ce  head=790b44ce  SAME
data/terrain/playground/manifest.json main=ded90a9b  head=ded90a9b  SAME
data/scatter/playground/manifest.json main=be3cf87b  head=be3cf87b  SAME
git diff --name-only origin/main...HEAD -- 'data/config/bands/**/vegetation.json' \
    'data/scatter/**' 'data/terrain/**'   → 0 files
```

Every input to both assertions is unchanged, so the verdict on `main` is identical. The
staleness landed with a config edit on `main` (the bakes were last re-run at `3c73aab5`);
the fix is a re-bake and commit of `data/terrain/playground` and `data/scatter/playground`,
which is outside this lane's ownership list and is left to the coordinator. It has a
player-visible cost worth flagging: with the scatter bake stale, every boot recomputes the
full corridor scatter — `smoke_save_persistence` above spent several minutes in
`vegetation.gd::build()` before its first frame.

### Icon provenance

`tools/gen_alpha_pin_icon.py` was re-run against the committed PNG: it reproduces
`assets/ui/icons/map/alpha.png` **byte-identically** (`cmp` clean), so the committed asset
is the generator's output and not a hand-edited divergence.

