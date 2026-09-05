# N14-ROUTED-FOLLOWUPS-0905

**Branch:** `ralph/N14-ROUTED-FOLLOWUPS-0905`
**Base:** `origin/main` at `4acd59ff`, plus merges of `ralph/N04-DIALOGUE-PORTRAITS-0905`,
`ralph/N07-VFX-POLISH-0905`, `ralph/N09-BRIDGE-CHECKPOINT-0905` and `ralph/N13-NIGHT-RESUME-0905`
**No pull request opened** (a separate landing lane handles that, per the brief).

Six of the seven numbered items are done and verified. Item 5 is done except its §5, which is
stopped and re-classified as Bucket-B on the brief's own instruction — see §8. Nothing in the
Bucket-B list at the end of the brief was attempted; all five are re-confirmed still open in §9.

---

## 0. Before anything else: the merge, and one thing the brief did not predict

The brief's merge sequence was followed exactly. It predicted clean merges ("these four touch
disjoint files from each other"). **Three of the four conflicted, and the brief's prediction was
right about the reason it gave — none of the conflicts is lane-versus-lane.** All four lanes
branched from `f8a47ee4`; `main` has since moved to `4acd59ff` (PR #52, eight lanes landed), and
every conflict is a lane against that landing:

| Merge | Conflict | Resolution |
|---|---|---|
| N04 | `scripts/ui/dialogue_panel.gd` | Both sides kept. W08 (landed) added `_pull_the_camera_out()` to `_on_runner_finished`; N04 added `_identity = {}`. They are adjacent lines doing unrelated things. |
| N04 | `docs/CURRENT_STATE.md` | Three rows on `main`, one on N04, and one of the three is the SAME row ("Every NPC speaks with the player's face"). Kept `main`'s other two, replaced that one with N04's — the file's own hygiene rule is "rewrite the relevant row, do not append layers", and N04's is the later state of that row. |
| N09 | `docs/CURRENT_STATE.md` | Two additive table rows in §7. Both kept. |
| N13 | `docs/CURRENT_STATE.md` | Two rows each side, and both sides carry BOTH rows at different dates. Kept `main`'s loft-bed row (W16 closed it on 2026-09-05; N13's copy still says open) and N13's night row (root-caused 2026-09-05; `main`'s copy is the older 2026-09-04 reopening). |

**This is a landing-lane finding and is why it is first here:** every 0905 lane is based on
`f8a47ee4`, and `docs/CURRENT_STATE.md` is a single long table that four of them rewrote rows in.
Whoever lands this wave will hit the same conflict once per lane, and the correct resolution is
never "take mine" — it is per-row, by date.

### The D87 collision — noted, not resolved

Confirmed present in the merged tree, four files, four different lanes, same number:

```
docs/decisions/D87-a-shared-line-borrows-its-speakers-face-and-hair-colour-is-laid-on-by-mask.md   (N04)
docs/decisions/D87-the-checkpoint-narrows-the-road-and-its-guard-wears-the-colour.md               (N09)
docs/decisions/D87-the-dark-semantic-is-narrower-than-the-visible-night.md                         (N13)
docs/decisions/D87-the-wind-up-ring-is-magenta-and-the-seal-flash-is-sized-to-the-orb.md            (N07)
```

Left exactly as their lanes wrote them. This lane took **D91**, the next number clear of all four,
per the brief. Renumbering is the landing lane's call.

---

## 1. Item 1 — shadows. The largest finding in the lane, and it was not what it looked like.

**Source:** N09's `JUDGE2.md` round 2, item 1, quoted in its REPORT's "Findings routed on" §1.
A blind judge, unprompted, ranked it as the single loudest defect anywhere it looked: *"Nothing in
the game casts a shadow… Zoomed to 8×, the trainer's boots meet pale ground with zero darkening
and zero contact occlusion."* Its diagnosis: *"Turn on shadow casting for the directional light."*

**Shadow casting was already on.** `world_look.gd::_apply_sun()` sets `shadow_enabled = true`,
`meadows_playground.tscn`'s own Sun node sets it, and `project.godot` sets a shadow atlas size and
a soft-shadow filter quality. So the brief's first instruction — confirm before spending the
budget — was the right one, and it took three measured rounds to find the real knob.

**Round 0, the cheap half (`tools/_probe_shadow_capability.gd`, new).** One box on one plane under
the exact sun `art.json` asks for, through the same `--rendering-driver opengl3` path every capture
tool uses. Seconds, not tens of minutes.

| variant | shadowed | lit | ratio |
|---|---|---|---|
| a-game-settings (what `world_look.gd` installs) | 0.5029 | 0.9248 | **0.544** |
| b-shadows-off (control) | 0.7141 | 0.7069 | 1.010 |
| f-exaggerated-control | 0.3699 | 0.7336 | 0.504 |
| g-game-environment (+ `art.json`'s own `ambient_energy` 1.9) | 0.7828 | 1.0000 | 0.783 |

**This container's software GL draws directional shadows, and draws a strong one under the game's
own sun settings.** "Software GL simply doesn't render shadows" was ruled out before anything was
changed.

> **The probe's first run reported the opposite, and the note is in the file.** `look_at` on a node
> not yet inside the tree silently left the camera unaimed, both sample windows landed on empty lit
> ground, every variant read ratio ≈1.00, and the probe printed "this renderer draws NO directional
> shadow at all" — the answer it was looking for. Caught by reading the `ERROR:` lines and by
> opening the saved PNG, which showed a perfectly good shadow. Sample windows are now checked
> against the saved frame, not trusted.

**Round 1, the real world (`tools/_capture_n14_shadow_ab.gd`, new).** N09's own graded stands, four
variants from ONE load (a software-GL world load costs 20–50 minutes; this is why the tool varies
in-place rather than running once per setting). At `shadow_max_distance` **420** the checkpoint has
no ground shadow at all; at **120** every prop, barricade and figure casts one. Same frame, same
load, one number changed.

**Round 2: is it the reach or the bias?** `shadow_bias` is scaled by the cascade's depth range, so
0.06 is centimetres at 120 m and metres at 420 — `_apply_sun`'s own comment even warns "lower it if
small props stop casting". **It is not the bias.** At 420 with bias 0.002 and normal_bias 0.8 the
ground is still shadowless. At 220 and at 120 the shadows are back. The reach is the knob.

**Shipped: `art.json` `sun.shadow_max_distance` 420.0 → 220.0.** Not 120: 220 is
`_apply_sun`'s own code default (`cfg.get("shadow_max_distance", 220.0)`), it is what this project
shipped before T1-HALL-4 raised it, and it was rendered at all three stands.

**What this trades, stated in `art.json` next to T1-HALL-4's own note rather than buried:** that
lane raised 220 → 420 to get crenellation shadows down the fortress parapet at long range, and got
them. Nobody measured what it cost at short range, and what it cost was every contact shadow in the
game. If the fortress needs its reach back, the honest answer is a per-preset override of a key
that is already overridable per time-of-day — not a global 420 that blanks the shadow everywhere
the player actually stands.

### Blind judge (code-blind sub-agent, given only the sheet and `docs/reference/`)

`_sheet_shadows_ab.png` — three stands, A (420) vs B (220). Full verdict in `JUDGE_shadows.md`.
It measured the difference independently and to the same conclusion:

> **"There is a real, substantial and consistent difference… column B renders near- and mid-field
> cast shadows that column A does not render at all. In all three rows."**

Whole-frame mean luma is unchanged (B/A 0.997 / 0.998 / 0.995), so nothing global moved. Shadowed
regions drop to **0.51–0.65×**; unshadowed controls of the same material a few tens of pixels away
move by **under 1%**. Its answer to the diorama question:

> **"Column A — pasted. Nothing in A touches the ground… Column B — mostly standing… A reads as
> flat elements on a backdrop. B reads as objects standing on ground, imperfectly."**
> **"Which column I would ship: B, without hesitation."**

It also gave an honest caveat, kept here because it is true: at 30% zoom the A/B difference is
"close to invisible in rows 2 and 3", and none of the frames' other defects is fixed by it.

**Two follow-ups it raised, NOT actioned here:**
- *No ambient occlusion anywhere.* B supplies the long directional shadow but not the tight contact
  darkening. `ssao_enabled: true` is in `art.json` and in the scene's Environment, and the
  Compatibility renderer this project ships does not implement SSAO — so that key is currently a
  no-op. Real, out of this lane's scope, and worth its own lane.
- *One crate casts nothing in either column.* Possibly a per-mesh `cast_shadow`, possibly an
  artefact of the judge's control region (it compared a dirt path against grass, two materials with
  different albedo). **Recorded, not acted on: the diagnosis is not yet safe to act on.**

---

## 2. Item 2 — the day/night clock now has a memory

**Source:** N13's REPORT §5 and §11 item 1. *"The clock has no memory… Every world starts at 08:00;
nothing saves or restores the hour; a realm crossing, a Continue and a rest all put it back."*

| File | Change |
|---|---|
| `autoload/game_state.gd` | `clock_elapsed_seconds` (`CLOCK_UNSET` = −1 → "open at the authored morning"). `_sync_clock_state()` reads the live world before a save and before `enter_realm()`'s `change_scene_to_file()`; `_restore_clock_to_world()` pushes it into a live clock on a mid-session load; `reset_for_new_game()` clears it. |
| `scripts/save/save_game.gd` | **VERSION 18 → 19.** Writes and reads the key; `_migrate_v18` gives every older save the sentinel rather than inventing an hour it never had; a non-finite or negative value falls back to the sentinel instead of restoring hour NaN. |
| `scripts/world/world_look.gd` | `resume_at_elapsed()` / `elapsed_seconds()`; `_ready()` resumes from the carried value instead of the unconditional `apply_time(DEFAULT_TIME)`. A rest still snaps to morning and now clears the carried value too. |

**New Game still opens at 08:00.** That is the whole reason the value lives on `Game` rather than in
a `static var` on `world_look.gd`, and it is N13's own stated reason for refusing to do the half it
could see: a static would survive New Game too. Recorded as **D91**.

**One defect found only by running it.** `playground_world.gd::_reapply_look_after_ground_materials()`
re-pushed the current look through `apply_time()`, which by its own R5.1 contract PINS the clock to
the named preset's authored hour. Harmless while every world opened at 08:00; fatal the moment one
could open at 19:40 — the re-push snapped a resumed evening back to `golden`'s 18:00 on every boot,
measured at exactly 18.00 where 19.67 was expected. New `world_look.gd::reapply_current_look()`
pushes the same look off the live clock instead of writing to it; `apply_time()` itself is unchanged,
so the pinning contract every capture tool depends on still holds.

### Verification

- `tests/test_save_format.gd` — **59 tests / 320 assertions, 0 failed.** Three new tests, each seen
  red first for the right reason: dropping the write key → *"the clock did not survive the save"*;
  a blind `float()` cast → the corrupt-value case. All three go through the saver's real
  `save()`/`load_slot()` API — **not** `save_game()`/`load_game()`, which is exactly the defect
  N01-SAVE-FORMAT found had left five tests in this file green for days without a single assertion
  running.
- `tests/smoke_clock_survives_a_reload.gd` (**new**) — the half a unit test cannot reach. A real
  booted world set to 19:40, saved, torn down, and a **second** world built from the file.
  **Seen red at hour 8.00 on the old `_ready()`; green at 19.67 after.** Also covers the crossing
  sync and New Game opening at 08:00. One thing worth knowing is written into its header: `_process`
  is fed wall-clock delta, and a software-GL world build spends minutes inside a handful of frames,
  so 562 seconds of a 600-second day went past during the settle loop and the clock lapped. The
  smoke freezes the clock on the same line it starts running.
- `test_day_cycle`, `test_day_cycle_night_contrast`, `test_world_weather`, `test_hud_widgets` —
  117 tests / 549 assertions, 0 failed.

`docs/CURRENT_STATE.md`'s night row is rewritten to close the routed half; CL-O2 is closed.

---

## 3. Item 3 — the three stuck pickup sites, un-buried

**Source:** N02's REPORT §7, first bullet. Three authored Rare/Great sites warned
`sits inside solid scatter and no spot within 5m was clear; move it` on every boot.

The brief said to try widening `NUDGE_RADII_M` first and re-author only if that fails. **Both were
needed, and the widening alone was a trap worth recording.**

- **Widened** `[2.0, 3.5, 5.0]` → `[2.0, 3.5, 5.0, 6.5, 8.0]`. Safe by construction, not by luck:
  `_clear_spot()` walks the radii smallest-first and returns on the first clear bearing, so
  appending larger rings cannot move a site that already resolves. That property is now held by a
  test, because it is what a future widening could break.
- **It solved two of three** — at 8.0 m and 6.5 m, far enough that the find no longer stands where
  its authored `why` says — and left `b4_candy_wind_ridge_crest` unsolved.
- **So all three were re-authored**, against measurements from `tools/_probe_n14_pickup_ground.gd`
  (new), which asks the same `vegetation.gd::has_solid_scatter_near()` the placer uses over a 0.5 m
  grid instead of 12 bearings on discrete rings:

| site | authored | measured nearest clear | now |
|---|---|---|---|
| `b4_candy_wind_ridge_crest` | (463.0, 5896.7) | 4.7 m | (467.0, 5899.2) |
| `b4_candy_herd_bull_highfield` | (442.0, 5829.7) | 6.0 m | (446.5, 5833.7) |
| `b5_candy_alpha_galecrest_pack` | (−50.0, 7268.0) | **0.5 m** | (−50.5, 7268.0) |

Each entry's own `why` records the move and why the place it is about is unchanged.

**Measured through `tests/smoke_playground.gd`:**

```
before   101 placed / 22 nudged / 3 unclear
after    101 placed / 22 nudged / 0 unclear
```

The nudge count is unchanged, which is the point: **no site is relying on the new rings.** No new
site warns.

**Found while measuring, NOT fixed** (recorded in the constant's own note): the ring-and-bearing
sample steps over clear ground it never asks about. `b5_candy_alpha_galecrest_pack` had clear ground
**0.5 m away** and was being walked 6.5 m, because the smallest ring is 2.0 m;
`b4_candy_wind_ridge_crest` had clear ground at 4.7 m on a bearing between two samples and was
called unsolvable. A finer first ring would place better AND closer to authored — but it would move
all 22 currently-nudged sites, which is a re-verification of the whole set, not a drive-by.

The boot log now distinguishes the two cases: a nudge over 5 m says *"re-author it if its `why` is
about the exact spot"*, and an unsolved site says *"RE-AUTHOR its coordinates"* rather than the
ambiguous *"move it"*.

**Verified:** `test_band_pickups.gd` 27 tests / 25,948 assertions, 0 failed (five new nudge tests;
`test_a_site_enclosed_past_the_old_ceiling_is_now_solved` seen red on the old list).
`test_band4_upper_meadows`, `test_band_content`, `test_camp_supply_reaches_every_band` — 46 tests /
28,880 assertions, 0 failed (these hold the 4.5 m separation and in-band rules the new coordinates
have to keep).

---

## 4. Item 4 — the catch-seal composite, all four

**Source:** N07's "Known limitations", all four quoted there with measurements.

1. **`impact_flash.gd`'s nine hard-edged spikes.** N07 could not soften them because that script is
   shared by every attack in the game. It is a **parameter** now — `spike_softness`, default 0.0,
   which is the flat triangle every attack has always drawn — read by each caller from its own data.
   `catching.json`'s `caught` sets 0.75 and is the **only** thing in the project that opts in;
   `combat.json`'s `impact.quick`/`impact.charged` deliberately do not, so **no blow in the game
   changes look on this commit**, and a test holds that.
2. **`vfx.json` `catch_burst`.** *The first attempt was wrong, and the arithmetic is the interesting
   part, so it is in the file.* Raising `speed` and WIDENING `speed_variance` moves the leading edge
   and leaves the slow tail exactly where it was — and the slow tail is what sits on the orb.
   `vfx_burst.gd` eases displacement (`1 − (1 − u)^2.2`) rather than running at constant speed, so
   at three ticks the shipped burst's **fastest** motes were already 0.672 m out and clear of a
   0.60 m orb while its **slowest** were at 0.224 m, deep inside it. `speed` 4.2 → 8.1 with
   `speed_variance` 0.5 → 0.30 raises the floor: slowest 0.605 m, on the rim rather than inside it.
   `count` 26 → 16. Everything else untouched.
3. **`orb.gd`'s halo**, N07's round-1 judge's *"clearest rendering bug in the catch sequence"*. It
   was one triangle fan: 18 segments and a single **linear** alpha ramp from an opaque centre to a
   transparent rim — which is exactly what "hard-edged trapezoid" describes. Now 32 segments and
   three concentric rings on a curve, `(1 − t)^2.2`.
4. **`catching.json` `resolve_camera`**, W09's judge's *"indistinguishable from a bug"*.

### The resolve camera is a worked correction, and it is recorded as one

The first pass raised `height` 0.55 → 1.35 to clear the ally, rendered it, and got back a seal with
**the orb sliced off the bottom edge of frame**. `height` is not the camera's elevation:
`camera_rig.gd:380` makes it the pivot offset — how far ABOVE the orb the frame is centred — and
1.35 m in a shot whose half-height is 1.10 m puts the subject outside the frame.

Reverted to 0.55. The lens is lifted with the **pitch** instead, which moves the camera without
moving the frame:

| | distance | height | fov | pitch | lens above pivot | horizontal standoff | half-frame at subject |
|---|---|---|---|---|---|---|---|
| shipped | 2.4 | 0.55 | 50 | −22° | 0.90 m | 2.23 m | 1.12 m |
| **now** | 3.4 | 0.55 | 36 | −40° | **2.19 m** | **2.60 m** | **1.10 m** |

The close-up survives because the distance is bought back with the lens: half the frame width at the
subject is `distance · tan(fov/2)`, within 2% of the framing an earlier pass had already accepted
(and well clear of the 1.49 m that same pass rejected as "the orb huddled small at the bottom of the
frame"). The test now carries a `height ≤ 0.8` bound so the same mistake **fails rather than
renders**.

### And a fifth thing, found by rendering

The halo fix turned out to be the smaller half of N07's "hard-edged trapezoid on the ground". The
rendered frame still showed a straight-edged translucent band lying across the grass, and it is
`orb.gd`'s **trail**: one `TRIANGLE_STRIP` two vertices wide, so its alpha fell away along its
length and **not at all across its width** — a ribbon with two hard straight sides. Now three
vertices wide, a lit spine between two zero-alpha edges.

**Verified:** `test_combat_vfx.gd` 13 tests / 77 assertions, 0 failed, with four new bounds tests
holding the arithmetic each change was argued from — **all four seen red on the shipped values**.
`test_catching`/`test_orb`/`test_telegraph_glow`/`test_camera`/`test_conversation_camera` 53 tests /
246 assertions, 0 failed. `tests/smoke_catching.gd` OK — a throw aimed, missed and landed, and the
caught creature reaching `Game.party`.

Frames re-rendered through the same harness N07 used (`tools/_capture_vfx_polish_0905.gd`);
before/after sheet at `_sheet_catch_ab.png`, blind verdict in `JUDGE_catch.md`.

---

## 5. Item 5 — South Bridge checkpoint

### §3 — the grey blockout slab: fixed

N09's judge: *"A flat blue-grey plate (median ~(120,128,133), essentially uniform)… the one piece of
undisguised placeholder left in column A, and it sits at the exact centre of the composition."*

Identified by rendering the recipe in isolation (`tools/_capture_bridge_deck_isolated.gd`, ~2
minutes, no world load): it is the kit's `Prop_ExteriorBorder_Straight1/2`, an untextured grey plate
capping each approach.

N09's prescription was "a material already in the same frame". This uses a **module** already in the
same frame instead: `Floor_UnevenBrick`, the cobbled stone the same recipe already lays at ±8 for
the abutment landings, one slab further out. No new asset, no new material, nothing to retint. The
`colliders` block is untouched — it already reached ±9.2, past both the old border and the new slab
— so the walkable extent and the gate's seal are exactly as they were, and `smoke_traversal`
confirms it ("the South Bridge is shut without its key and open with it").

### §6 — the lantern through the sentry: fixed

`LANTERN_SIDE` 2.0 → 2.6, the number N09 measured and would not ship because it could not verify it
without another full render. The lantern moves rather than the sentry, whose position carries a
paragraph of reasoning in `south_bridge_dressing.json::_why_here` (clear of the smoke walk and the
road's half-width, inside the staked banners, outside the challenger's 4.2 m prompt radius); the
lantern's position carries none, and 0.6 m further out keeps it inside the banners at z = ±2.7.

### §10 — the stale `_comment_oxblood`: fixed

`npc_ranks.json` still described the grunt/officer/captain body palette as *"a warm rose-red family
multiplied onto the grunt rig's own dark tactical texture"*. T1-GROUND replaced that with a **neutral
value ladder** (`#dcdcdc`/`#eeeeee`/`#ffffff`) five days earlier, and the stale description was still
being read as current — N09 went looking for the multiply it promised and found a neutral 0.86×.
Rewritten to describe what the file does, with the badges half (still the warm-red family, and still
true) kept and marked as such.

### All three fixes confirmed in one real-world frame

`_sheet_checkpoint_ab.png` — `bridge-approach-played` and `bridge-checkpoint-shoulder`, before (A)
and after (B), same tool, same stands. The B frames carry **three** of this lane's changes at once
and all three are visible in them:

- the barricades, the crate, both banner poles and both figures now cast shadows on the ground
  (item 1);
- the grey plate in front of the gate is now cobbled stone (§3);
- the lantern hangs clear of the sentry, who is no longer cut in half by it (§6) — the number N09
  measured and would not ship unrendered, now rendered.

`place5-bridge-approach` was re-rendered at its new stand in the same load: the crossing is now the
subject of the frame — deck, rope rail, gully and the sentry at the gate all legible — instead of a
soft smudge at 30 m. Frame at `shots/n14/checkpoint_after/`.

### §5 — the barricade silhouette: **STOPPED, and re-classified as Bucket-B**

N09's judge: *"A single hip-height rail on an X frame. No stakes, no points, no lashings, no rope,
no crossed spears… The iron bands are good; the form is wrong."*

The brief lifted N09's geometry restriction for this lane and then said, in as many words: *"If this
starts to feel like an art/silhouette decision rather than an engineering fix, stop and document it
as Bucket-B instead of guessing at a look — the line CLAUDE.md draws is real and this is the item
most likely to cross it."*

It does. There is no engineering answer to "what shape is a Team Tether barricade" — the judge's
list (stakes, points, lashings, rope, crossed spears) is five different objects, each a different
statement about who built this and how hastily, and picking one is choosing the faction's field
carpentry. `south_bridge.gd` builds these frames procedurally, so it is easy to *make* the change and
that is exactly the trap. **Stopped without touching the geometry.** It needs an owner sketch or a
board reference, and then it is an hour's work.

---

## 6. Item 6 — portraits

### Hue spacing: fixed, and measured on the rendered plates

N04's judge, once the per-NPC hair colour was finally visible, measured three pairs still reading as
the same person at speaking distance. Spread by **value inside each colour's own family** — the
family each person belongs to was a deliberate call and is not reopened:

- **Rae** `#7a4a2c` → `#a8663f`. Hue 23.1° → 22.3° and saturation 0.64 → 0.62 (unchanged to within
  rounding); only value moves, 0.48 → 0.66. She was in **two** of the three flagged pairs, so moving
  her alone answers both.
- **Halda** `#8f8f96` → `#63636e`. Hue identical at 240°, value 0.59 → 0.43 — iron rather than
  pewter, separating her from Tam's lighter, warmer silver.

Measured on the **rendered plates at 72 px**, the size N04's judge measured at, with the threshold
chosen before the re-render (the bar is the 14.05 that Mira-vs-ranger already sat at *without* being
flagged):

| pair | before | after |
|---|---|---|
| rae vs villager_ranger | **6.83** | **16.23** |
| halda vs tam | **9.84** | **17.34** |
| rae vs mira | **11.11** | 27.05 (off the closest-pairs list) |
| mira vs villager_ranger (never flagged) | 14.05 | 14.05 |

Both plates re-rendered; sheet at `_sheet_hair_spacing.png`.

**Found and fixed while doing it:** `tools/_capture_portraits.gd` **duplicated** both hexes as
literals, so changing `village_npcs.json` alone would have left the pre-rendered plates showing the
old heads forever with nothing failing — the exact shape of defect W04 and N04 each spent a lane on.
New `test_the_portrait_tool_agrees_with_the_world_about_hair` holds the two in sync; seen red with
the tool's literal reverted.

### The male rig: fixed, and the feasibility question answered with a measurement

N04's report flagged "the male rig has no separable hair and no mask" as a real possibility that
would end this work, and `art.json::villager_keeper` says the same about the mesh. **Both are true
about the MESH and both are beside the point: the mask is a region of the TEXTURE, found by skinning
and colour, not a mesh to be cut.**

Measured on the real rig before writing anything: the head-bone-skinned UV islands cover **425,806
texels** of `texture_0`, and inside them N04's own colour key separates cleanly into hair islands and
face islands. The tunic — which is the same warm-brown family as the hair and *would* defeat a colour
test applied to the whole atlas — is outside the head region and never considered. (61% of the whole
atlas matches the hair colour key; 62.3% of the *head region* does. The head-region restriction is
what makes it work.)

- `tools/_bake_villager_male_hair_mask.py` (new) bakes `villager_male_lod0_hair_mask.png`. It
  **imports** the female script's GLB readers rather than copying them, so the two rigs cannot drift
  in how they read a glTF. N04's thresholds are **reused because they were measured to fit, not
  assumed to**: the male rig's painted hair sits at luma p05 13 / median 25 / p95 46 against the
  female's 10 / 23 / 44. Result: 260,513 texels kept in 29 components, 8.7% of the atlas.
- `character_model.gd::_apply_hair` reaches the painted recolour on a rig where
  `find_child("hair_ponytail")` returns null — placed **before** the primitive placeholder,
  deliberately, because falling through would put a ball of hair-coloured plastic on the five people
  this is meant to tell apart.
- Oskar `#2f2320`, Bram `#9c8450`, Kell `#a49e99`, Quarry Foreman `#74512f`. Worst CIE76 ΔE among the
  four is **21.38**, against the 6.83 N04's judge flagged. This rig's two previous differentiators
  are both recorded in `art.json` as tried and reverted — a whole-body tint ("looks stupid", owner
  playtest) and a per-material belt pouch (rendered in the wrong place).
- Four new plates rendered, and **14 dialogue conversations** re-pointed off the generic
  `villager_male.png` to their speaker's own plate. Sheet at `_sheet_male_hair.png`. The two
  remaining `villager_male.png` lines are the generic trainer refusals in `trainers.json`, which N04
  made wear the challenged trainer's identity at runtime — left alone.

**No new mesh, no new humanoid, no Meshy spend**: the mask is a region of the rig's own texture, so
this does not touch CLAUDE.md's humanoid-cast restriction. **Eyebrows untouched**, per N04's
deliberate call and this brief's instruction.

**Verified:** 158 tests / 4,717 assertions, 0 failed across `test_villager_male_painted_hair` (new,
8 tests), `test_villager_female_painted_hair`, `test_dialogue_portraits`, `test_character_hair_split`,
`test_character_metallic`, `smoke_art`, the dialogue and village suites and `test_trainers_data`.
Four of the eight new tests seen red with the maskless-mesh branch removed — including
`test_a_maskless_mesh_rig_does_not_grow_a_placeholder_hair_ball`, which confirms the placeholder
really would have appeared.

---

## 7. Item 7 — low-priority cleanup, both done

- **N12 §8, the 30 dead `.import` sidecars.** Untracked, with a `.gitignore` rule. **Not a blanket
  rule:** eight `reference/` directories carry no `.gdignore`, the editor does import those, and
  their **21** sidecars are live files that stay tracked — they are named as exceptions in the rule.
  Whether those eight should also be `.gdignore`d is a real question this does not answer.
- **N09 §9, `place5-bridge-approach`.** The camera stand three independent blind judges (W05's,
  W22's, N09's) have now flagged rather than the crossing it points at. **The cause is the distance,
  not the height:** the eye stood **30.5 m** from its target, so the crossing arrived through the
  full depth of this world's aerial-perspective fade as a smudge, and 2.2 m of eye height read as
  knee height at that range. **16.4 m and 3.0 m** now, still looking along the road from the village
  side.

---

## 8. Known limitations and what was deliberately not done

- **Item 5 §5, the barricade silhouette** — stopped as an art decision, see §5 above. This is the one
  numbered item in the brief that is not done.
- **The A/B shadow difference is real but not dramatic at 30% zoom.** The judge said so and it is
  repeated here rather than buried: the change matters at play distance and does not alter what the
  frames read as from across a room.
- **SSAO is a no-op on this renderer.** `art.json` and the playground scene both enable it; the
  Compatibility renderer does not implement it. The judge's "no ambient occlusion anywhere" is
  therefore accurate and is a real, unowned gap. Not this lane's to fix.
- **One crate casts no shadow in either column.** Recorded in §1; the judge's diagnosis
  ("cast-shadow disabled per-mesh") may be an artefact of its control region comparing dirt against
  grass, and acting on an unverified diagnosis is worse than recording it.
- **The nudge search's ring-and-bearing sampling** steps over clear ground, see §3. A finer first
  ring would place better and closer to authored, and moves all 22 nudged sites.
- **`tools/_capture_n14_shadow_ab.gd` duplicates `place5-bridge-approach`'s coordinates** from
  `tools/_capture_band1_places.gd` by hand. Noted in the file; that file is the one that ships.
- **The 12 missing `.uid` sidecars on `main`** (N02 §7, N07's limitations, N09's own routed note) are
  still missing and are still N12's. This lane deliberately did not commit them; only its own new
  scripts' sidecars are committed.
- **Software GL.** Every frame in this lane is a Compatibility-renderer software capture.
  Composition, presence, colour relationships, scale and the presence or absence of a shadow are what
  they prove; fine lighting is not.

---

## 9. Bucket B — re-confirmed still open, still accurately described

Checked against the source reports as the brief asked. All five are still open and all five
descriptions still hold:

1. **The checkpoint can be walked around on the grass verges** (N09 §2). Still true — nothing in this
   lane touched the verges, and the fence/palisade asset the judge could not find is still not
   installed. Reopens D86's own deliberate choice; owner decision.
2. **The hero gate's blue banners** (N09 §4). Still true — `south_bridge_gate.glb` is still one node,
   one mesh, one material, one baked atlas, with no separable cloth slot. Needs a Team Tether asset
   regeneration or a hand repaint. Asset-ledger owner's call.
3. **The lantern's cyan reads as a defect in daylight** (N09 §7). Still true. This lane **moved** the
   lantern (§6) and did not touch its colour; `tether_teal` is reserved by D86.
4. **Signpost glyph cap height** (N09 §8). Still true — needs a physically bigger board mesh or
   shorter route labels.
5. **Eyebrows** (N04). Still true and still deliberate; untouched.

**Newly proposed for Bucket B by this lane:** item 5 §5, the barricade silhouette (§5 above).

---

## 10. Files changed

**Source and data**

```
autoload/game_state.gd                      scripts/save/save_game.gd
scripts/world/world_look.gd                 scripts/world/playground_world.gd
scripts/world/band_pickups.gd               scripts/world/south_bridge.gd
scripts/characters/character_model.gd       scripts/combat/impact_flash.gd
scripts/combat/orb.gd                       scripts/combat/combat_manager.gd
data/config/art.json                        data/config/catching.json
data/config/vfx.json                        data/config/village_npcs.json
data/config/npc_ranks.json                  data/config/building_prefabs.json
data/config/bands/band4_upper_meadows_ironwood/pickups.json
data/config/bands/band5_stronghold_approach/pickups.json
data/dialogue/village.json                  data/dialogue/meadows_freed.json
.gitignore
```

**Tests**

```
tests/test_save_format.gd            (+3)   tests/smoke_clock_survives_a_reload.gd   (new)
tests/test_band_pickups.gd           (+5)   tests/test_villager_male_painted_hair.gd (new, 8)
tests/test_combat_vfx.gd             (+4)   tests/test_dialogue_portraits.gd         (+1)
```

**Tools**

```
tools/_probe_shadow_capability.gd      (new)   tools/_capture_n14_shadow_ab.gd     (new)
tools/_probe_n14_pickup_ground.gd      (new)   tools/_bake_villager_male_hair_mask.py (new)
tools/_capture_portraits.gd            (male-rig plates)
tools/_capture_band1_places.gd         (place5 stand)
```

**Assets**

```
assets/characters/villager_male/villager_male_lod0_hair_mask.png   (new, baked)
assets/ui/portraits/{oskar,bram,kell,quarry_foreman}.png           (new)
assets/ui/portraits/{halda,rae}.png                                (re-rendered)
30 dead .import sidecars untracked
```

**Docs**

```
docs/CURRENT_STATE.md                                                    (night row)
docs/decisions/D91-the-hour-of-day-is-saved-state-and-a-new-game-clears-it.md   (new)
```

**Evidence in this directory**

```
JUDGE_shadows.md          _sheet_shadows_ab.png
JUDGE_catch.md            _sheet_catch_ab.png
                          _sheet_checkpoint_ab.png
                          _sheet_hair_spacing.png
                          _sheet_male_hair.png
```

---

## 11. Commits

<!-- FINAL-COMMIT -->
