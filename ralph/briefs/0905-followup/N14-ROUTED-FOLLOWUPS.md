# N14-ROUTED-FOLLOWUPS

**Source:** the routed findings left by nine of this wave's own lanes once they finished —
N02-VEGETATION, N04-DIALOGUE-PORTRAITS, N07-VFX-POLISH, N09-BRIDGE-CHECKPOINT,
N12-REPO-HYGIENE and N13-NIGHT-RESUME each correctly stopped at their own ownership boundary
and documented a fix outside it. This brief collects every one of those findings that is
launchable now (no new mesh, no Meshy generation, no invented design call) into one lane. Items
that need new art or a design decision only the owner can make are listed at the end and are
explicitly **not** in scope — do not attempt them.

## Before you start: merge, don't rebuild

Four of the six source lanes are done but **not yet landed on `main`**, and you are editing
files three of them already changed. Build your own starting point rather than guessing at
what `main` will look like after landing:

```
git fetch origin main
git checkout -B ralph/N14-ROUTED-FOLLOWUPS-0905 origin/main
git merge origin/ralph/N04-DIALOGUE-PORTRAITS-0905 --no-edit
git merge origin/ralph/N07-VFX-POLISH-0905 --no-edit
git merge origin/ralph/N09-BRIDGE-CHECKPOINT-0905 --no-edit
git merge origin/ralph/N13-NIGHT-RESUME-0905 --no-edit
```

These four touch disjoint files from each other, so the merges should be clean. If any of them
conflict with each other, stop and report it rather than resolving blind — that is itself a
landing-lane finding. **Do not merge N02 or N12** — you don't touch their files, no reason to.

**Decision-number collision, read before writing D-anything.** N04, N07, N09 and N13 each
independently wrote a `docs/decisions/D87-*.md` — four different files, same number, because
each lane's brief said "D87 is next free" and none knew about the others running concurrently.
After the four merges above your tree will have all four `D87-*.md` files side by side (the
merge won't conflict — they're different filenames). **Do not renumber them** — that's a
landing-lane call, not yours, and it's already flagged in the coordinator ledger. Take **D91**
for anything you write (the next number clear of all four collisions), and say in your report
that the D87 collision exists so it isn't lost.

Everything else: follow `ralph/briefs/0904/COMMON.md` in full (git, Godot install, testing
discipline, visual-judge process, report format, hard rules) and
`ralph/briefs/0905-followup/COMMON.md`'s general notes. Report at
`ralph/reports/N14-ROUTED-FOLLOWUPS-0905/REPORT.md`. Never open your own PR.

## Do, in this order — stop and write up honestly if you run out of runway

Work top to bottom. Each item names its source report for full context
(`ralph/reports/<LANE>-0905/REPORT.md` on that lane's branch, already in your tree after the
merges above) — read the cited section before touching the file.

### 1. Turn on shadows. This is the single highest-value item in this whole brief.
**Source:** N09-BRIDGE-CHECKPOINT's `JUDGE2.md` round 2, item 1 of its routed findings —
quoted in full in the REPORT.md's "Findings routed on" §1. A blind judge, unprompted, ranked
this as the single loudest defect anywhere it looked: *nothing in the game casts a shadow* —
not banners, not the gate, not props, not the trainer, not the guard. "Zoomed to 8×, the
trainer's boots meet pale ground with zero darkening and zero contact occlusion... This is the
loudest defect in the picture." The judge's own diagnosis: *"Turn on shadow casting for the
directional light and give the props a contact/AO term. No new asset. Highest value per hour
on this list by a wide margin."* This is `scripts/world/world_look.gd` (the world's
directional light) and whatever environment/shadow settings it configures — it affects every
frame in the game, which is exactly why it's worth doing first.
- These renders were software GL in a headless container. **Confirm the same reads true on a
  real renderer/GPU path before spending the budget on it** — check whether shadow casting is
  already enabled but invisible under `--rendering-driver opengl3` in this container versus
  genuinely off in the resource. If software GL simply doesn't render shadows regardless of
  the setting, say so precisely and move to item 2 rather than guessing.
- If it's a real gap: enable shadow casting on the directional light, and if there's a cheap
  ambient-occlusion or contact-shadow term available in the project's environment resource
  (SSAO, or per-instance `cast_shadow` on relevant meshes), turn it on. No new asset, no new
  shader — this is a settings/property change.
- Render a real before/after contact sheet (reuse an existing capture tool — `tools/survey.gd`
  or one of the `tools/_capture_*` scripts already in the repo) at 2-3 real locations
  (the South Bridge checkpoint one of them, since that's where it was found) and run a blind
  judge on it. This is exactly the kind of change that needs to be *seen* to be believed, not
  just asserted.
- **If it turns out to be bigger than a settings flip** (e.g., every mesh needs its
  `cast_shadow` property set individually, or performance tanks) — timebox it, document
  precisely how far you got and what the real remaining cost is, and move on. Don't let this
  one item eat the whole lane if it turns out to be a genuine multi-day systemic project.

### 2. Persist the day/night clock. The largest remaining piece of OP-0904-2.
**Source:** N13-NIGHT-RESUME's REPORT.md §5 and §11 item 1 — read it in full, it lays out the
mechanism precisely. Quoting the core of it: *"The clock has no memory... Every world starts at
08:00; nothing saves or restores the hour; a realm crossing, a Continue and a rest all put it
back."* `scripts/world/day_cycle.gd` holds the live clock; `scripts/save/save_game.gd` has no
clock key at all; `game_state.gd::enter_realm()` rebuilds the scene from nothing.
- Add the current hour (and whatever else `day_cycle.gd` needs to resume mid-cycle — check its
  own state, likely just the elapsed-time float) to the save format, and restore it on load.
- Fix the realm-crossing reset in `game_state.gd::enter_realm()` the same way — carry the
  clock across a scene rebuild instead of losing it.
- **New Game should still start fresh** (08:00, per existing behaviour) — this is about
  *continuing/loading/crossing*, not changing what a new save begins at. Don't invent a
  different starting hour; that would be exactly the kind of unrequested design call
  CLAUDE.md says to ask about, and nothing here asks for one.
- Write a save-format test that fails on the old code (save at a non-08:00 hour, reload,
  assert the hour survived) — this is squarely `test_save_format.gd` territory; check what
  N01-SAVE-FORMAT already fixed there so you extend it cleanly rather than reintroducing one
  of the bugs N01 just closed.
- Update `docs/CURRENT_STATE.md`'s night row again if this changes its status (check what N13
  already wrote there first).

### 3. Un-bury the three stuck pickup sites.
**Source:** N02-VEGETATION's REPORT.md §7, first bullet. Three authored Rare/candy pickups —
`b4_candy_herd_bull_highfield` (442, 5830), `b4_candy_wind_ridge_crest`,
`b5_candy_alpha_galecrest_pack` — sit inside solid scatter and are genuinely enclosed;
`scripts/world/band_pickups.gd::NUDGE_RADII_M` stops at 5m and can't find them clear ground.
N02's own framing: *"give those three sites a wider nudge budget or re-author them."*
- Try widening `NUDGE_RADII_M` first (check what it does to every other site's nudge results,
  not just these three, before committing) — it's the smaller change. If a wider radius still
  can't clear these three without landing them somewhere wrong, re-author their coordinates in
  `data/config/bands/*` instead.
- Verify with `smoke_playground` (N02's report says this is exactly what currently warns on
  these three sites) — confirm the warning is gone and no new site starts warning.

### 4. Catch-seal composite cleanup (all four routed by N07-VFX-POLISH).
**Source:** N07-VFX-POLISH's REPORT.md, "Known limitations" section — all four are quoted
there with the exact measurements. None needs a new asset.
- `scripts/combat/impact_flash.gd`'s nine radial spikes are hard-edged with no softness key.
  **This script is shared by every attack in the game** — add a softness/falloff parameter
  rather than hardcoding a change, and re-run whatever combat VFX tests/smokes exist to
  confirm nothing else using this script regresses.
- `data/config/vfx.json`'s `catch_burst` throws 26 motes that are still packed on the orb at
  three ticks, read by a blind judge as "dust or mud kicked up" burying it. Retune the burst
  (fewer motes near the origin, or a faster initial spread) so the orb isn't hidden.
- `scripts/world/orb.gd`'s ground halo renders as a hard-edged trapezoid with no falloff under
  software GL — add a radial falloff to the existing halo, no new mesh or texture.
- `data/config/catching.json`'s `resolve_camera` parks inside the ally creature's own rig
  (N09's judge: "indistinguishable from a bug"). Reposition it so the camera clears the ally.
- Re-render the catch sequence and run one blind judge round comparing against N07's own
  before/after — you're finishing what that lane's ceiling stopped at, so measure against it.

### 5. South Bridge checkpoint touch-ups (from N09-BRIDGE-CHECKPOINT's routed findings).
**Source:** N09's REPORT.md, "Findings routed on" §3, §5, §6, §10 — read each in full before
touching its file; §2, §4, §7, §8 are excluded, see the Bucket-B list below.
- **§3 — the grey blockout slab where the road meets the gate.** Undisguised placeholder,
  present on `main` too. N09's own diagnosis: *"the fix is a material already in the same
  frame (the gate piers' stone, or the gate's own plank)"* — apply an existing material, no new
  asset.
- **§5 — the barricade reads as a sawhorse, not a barricade.** *"A single hip-height rail on an
  X frame. No stakes, no points, no lashings, no rope, no crossed spears... The iron bands are
  good; the form is wrong."* N09 was scoped to materials/placement only and explicitly told not
  to change geometry; you are not under that restriction. Rebuild the frame's shape using the
  same primitives already in `south_bridge.gd` (it already procedurally builds these frames in
  code) into something that reads as a barricade — crossed stakes, not a sawhorse rail. **If
  this starts to feel like an art/silhouette decision rather than an engineering fix, stop and
  document it as Bucket-B instead of guessing at a look** — the line CLAUDE.md draws is real
  and this is the item most likely to cross it.
- **§6 — the lantern post visually bisects the posted sentry from the checkpoint's own played
  camera angle.** One-number fix: N09 measured the lantern needs roughly z +2.6 (crossing-
  local) to clear the sentry's silhouette from camera position (−16.4, −1.9). Move it and
  render to confirm — N09 didn't verify this because it would have cost another full render
  cycle it didn't have; you have the room to actually check it.
- **§10 — `data/npc_ranks.json`'s `_comment_oxblood`** describes the grunt/officer/captain
  palettes as "a warm rose-red family multiplied onto the grunt rig's own dark tactical
  texture," which T1-GROUND overwrote five days ago with a neutral value ladder. Fix the
  comment to describe what the file actually does now. One paragraph.

### 6. Portrait follow-ups (from N04-DIALOGUE-PORTRAITS's routed findings).
**Source:** N04's REPORT.md, "Findings that are not this lane's" paragraph.
- **Hue spacing.** Three NPC hair-hue pairs are still close enough to read as the same person
  at speaking distance (judge's ΔE at 72px: ranger/Rae 5.4, Tam/Halda 8.9, Mira/Rae 8.3). The
  colours live in `art.json` / `village_npcs.json` / `river_nest_clear.gd`, "chosen when they
  were invisible" per N04. Spread the three closest pairs apart within the same palette family
  each already belongs to — this is retuning existing hue values, not choosing new ones.
- **Extend the mask-by-region hair recolour to `villager_male.png`**, the same technique N04
  built for the female rig (`tools/_bake_villager_female_hair_mask.py` is the reference
  implementation — read it before writing an equivalent for the male rig). N04 didn't do this
  because its brief scoped it to the female rig; several male NPCs (Oskar, Bram, Kell, the
  Quarry Foreman, Coll) currently all share one undifferentiated plate. This reuses the
  already-installed male rig and its own existing texture — no new mesh, no new humanoid, no
  Meshy spend — so it does not touch the CLAUDE.md humanoid-cast restriction. If the male rig's
  hair genuinely has no separable region the way the female rig's mask found one (N04's report
  flags this as a real possibility — "the male rig has no separable hair and no mask"),
  document why and stop rather than forcing a bad mask.
- **Do not touch eyebrows.** N04 left them dark under recoloured hair deliberately, on the
  judgment that "a greying person with dark brows is a look, not a bug" — that's exactly the
  kind of call CLAUDE.md reserves for the owner. Leave it exactly as N04 left it.

### 7. Low-priority cleanup, only after everything above.
- **N12-REPO-HYGIENE's REPORT.md §8, first bullet:** 30 tracked `.import` files sit inside
  `.gdignore`'d `reference/` directories under `assets/creatures/tetherbound/*/reference/` —
  Godot never reads them. N12 called this "a one-line follow-up if wanted": remove them from
  tracking (they're dead weight, not a functional bug) if you have time left.
- **N09's REPORT.md §9:** the capture tool `tools/_capture_band1_places.gd`'s
  `place5-bridge-approach` viewpoint is shot at knee height with heavy depth-of-field blur —
  three independent lanes (W05, W22, N09) have now flagged the same bad camera stand. Fix the
  viewpoint definition if you have time left; this is tooling, not gameplay.

## Explicitly out of scope — Bucket B, do not attempt, just confirm they're still open

These all need either a new asset, a Meshy generation, or a design decision only the owner can
make. Confirm each is still accurately described in the source report (things may have moved
since) and leave them alone:
- **The checkpoint can be walked around on the open grass verges** (N09 §2) — needs a fence or
  palisade asset the judge couldn't find installed anywhere, and reopens D86's own deliberate
  choice about what may block a player at this crossing. Owner decision.
- **The hero gate's blue banners** (N09 §4) — the gate is one baked mesh/material/atlas with no
  separable cloth slot; needs a Team Tether asset regeneration or a hand repaint of the atlas
  texture. Asset-ledger owner's call.
- **The lantern's cyan reads as a defect in daylight** (N09 §7) — `tether_teal` is a reserved
  colour by an explicit design decision (D86); not a dressing lane's to overturn.
- **Signpost glyph cap height** (N09 §8) — needs a physically bigger board mesh or shorter
  route labels; Bucket-B per N09's own report.
- **Eyebrows** (N04, see item 6 above) — deliberate, owner's call.

## Verify
Every code change gets a red-then-green test where one's meaningful (save format, vegetation
siting, VFX config bounds). Run the full named test suites for every file you touch, not just
the ones you added. For anything visual (shadows, the barricade shape, the blockout slab
material), render real frames and run at least one blind judge round — assertions about "does
it look right" without a render are not acceptable here, same as every other lane this wave.

## Acceptance
As many of items 1-7 as you can genuinely finish with real verification, in priority order —
this is a big brief and nobody expects all of it in one pass. Write up exactly what's done,
what's partial, and what's still open (including re-confirming the Bucket-B list is accurate)
in `ralph/reports/N14-ROUTED-FOLLOWUPS-0905/REPORT.md`, following the same honesty standard
every other lane in this wave has held to. The D87 collision is noted, not resolved, in your
report.
