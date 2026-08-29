# Dark Features Inventory — 2026-08-30

Lane: `ralph/DARK-FEATURES`. Read-mostly audit. **Nothing was fixed** — see §6
for why, including the one item I was tempted by.

Owner directive this serves (2026-08-30):

> *"install everything we've done so far. if we built it, turn it on, put it on
> the game, make it playable."*

This is the list an install lane works off. It is **not** a fix plan and not a
priority call on the owner's behalf.

---

## 0. What tree this was measured against, and how

`ralph/LAND-0830B` **does not exist**. `ralph/LAND-0830` does, and it has
already landed: `main` is at `477a296a` = `LAND-0830`'s own handover commit,
with `LAND-0830` exactly one docs commit ahead. So `main` already carries
T1-CAST, T1-GROUND, T1-SKY, T1-UI, T1-HALL-DESIGN, T1-WARRENS-EXT,
T2-STRANDING, **T3-PICKUPS** and **T3-TYPECHART**.

Seven lane branches are **not** on `main`. I built a scratch integration tree
(`main` + all seven) and audited that:

| branch | merged clean into the audit tree? |
|---|---|
| `ralph/T3-ENCOUNTER` | yes |
| `ralph/T3-CREATURES` | yes |
| `ralph/T3-MATCHUPS` | yes |
| `ralph/T3-DENSITY` | yes |
| `ralph/T1-CREATURE-ART` | yes |
| `ralph/T1-CREATURE-MESH` | **no** — `docs/ASSET_LEDGER.md` |
| `ralph/T3-SUNSTONE` | **no** — `playground_world.gd`, `band5 spawns.json` |

**Method.** Every claim below was traced to a reader/caller/placement, not
inferred from one grep. Where I could not settle something I say so and say
what I checked. **Godot is not installed in this container** (`which godot` →
nothing, `$GODOT` unset), so *every finding here is static analysis*. Nothing
below has been confirmed by booting the game. Two findings (D1, T1) name the
specific play-test that would confirm them.

**I disproved two things I expected to confirm** — see §5. That section exists
so install lanes do not re-spend time on ground that is already solid.

---

## 1. Correction to the brief's premise — read this first

> *"Five new creature meshes now committed at
> `assets/creatures/tetherbound/{sparkit,shadelet,frostclaw,cindercub,bramblebun_redesign}/models/creature_<name>_lod0.glb`.
> They have no `.import` files and are not wired to their species entries."*

**This is not the case. No mesh exists, on any branch.** Checked with
`git ls-tree -r` against `main`, `T1-CREATURE-MESH`, `T1-CREATURE-ART` and
`T3-CREATURES`: the five directories contain **reference art only** —
`reference/{front,side,back,top}.png` plus a `.gdignore`. No `models/`
directory, no `.glb`, so the missing `.import` files are a symptom, not the
problem. (`.gdignore` there is correct — that is source art Godot should not
import.)

The lane was honest about this; nobody was misled but the brief.
`ralph/reports/handover-T1-CREATURE-MESH-2026-08-30.md`, line 5:

> *"This lane holds no Meshy API key and generated no mesh — everything below
> is reference crops, `views.json` entries, and prompts for the coordinator to
> run."*

**Why this matters for the install lane:** these five are not a wiring job.
They are blocked on a Meshy generation that has not happened, which under
`CLAUDE.md` needs owner-supplied reference art (it now exists) **and** is
constrained by the standing "no new creature meshes for Meadows" rule. That is
an owner decision, not an install task. It is item **C1** below.

---

## 2. Tier 1 — built, and the player cannot reach it

Ranked by player impact.

### D1 — All four Aspect variants render as their base species

| | |
|---|---|
| **What it is** | Nightburrow, Stormtrail, Riftfrill, Ashtusk — the owner's four expansion variants. Recolored + emissive textures are generated and committed; the runtime hook is built; the spawns are placed. The creatures appear in play wearing **their base species' default textures**. |
| **Where it lives** | Textures: 8 PNG + 8 `.import` under `assets/creatures/tetherbound/{burrowback,trailpup,paddlenewt,tuskroot}/models/*_{nightburrow,stormtrail,riftfrill,ashtusk}.png`. Spec: `data/creatures/aspect_variants.json`. Hook: `scripts/creatures/creature_body.gd::set_aspect_variant()` (L262) and `_build_placeholder()` (L286-297). Gap: `data/creatures/species.json`. |
| **What it would take** | **8 JSON keys.** Add `"aspect_variant"` and `"aspect_source_species"` to the `placeholder` block of the four species entries. The values are already in the file — `aspect_source_species` is exactly each entry's existing `variant_of` (`burrowback`, `trailpup`, `paddlenewt`, `tuskroot`); `aspect_variant` is the species id itself. |
| **How a player meets it** | Nightburrow in band2, Stormtrail in bands 3+4, Riftfrill in band3 (all three already in `spawns.json`); Ashtusk via the Sunstone evolution. Today each is a slightly-resized reskin-less copy of a creature the player already owns. |
| **Confidence** | **High.** |

**What I actually checked.** `_build_placeholder()` reads
`look.get("aspect_variant", "")` off the species `placeholder` block — I read
the function. I then dumped all four `placeholder` blocks: keys are
`colour, height, radius, footprint_allowance, model, model_scale, model_yaw,
animations` — **`aspect_variant` is absent from all four**. Every caller of
`set_aspect_variant()` outside `creature_body.gd` itself lives in `tools/`
(`_probe_stormtrail_swap.gd`, `_probe_aspect_vfx_perf.gd`,
`_capture_aspect_variants.gd`) — i.e. capture tooling only, no production
path. I confirmed the texture filenames satisfy `_texture_for()`'s contract
(L770-780), **including** Trailpup's odd one: its textures are embedded in the
`.glb`, so it takes the `%s_extracted_%s_%s.png` fallback branch, and
`trailpup_extracted_base_color_stormtrail.png` is on disk with that exact
name. So the wiring genuinely works; only the declaration is missing.

**This is a clean two-lane handoff gap, and both lanes were honest about it.**
`handover-T1-CREATURE-ART-2026-08-30.md` L180-187:

> *"**I did not add these two keys to `data/creatures/species.json`** — that
> file is T3-CREATURES' own … once T3-CREATURES lands … adding these two
> placeholder keys is the [remaining step]"*

T3-CREATURES then landed the four species entries without them. Neither lane
was wrong; the work simply fell between them. **This is the single highest
player-impact item in this report and the cheapest to close.**

---

### C1 — The five expansion species are fully authored and completely unreachable

| | |
|---|---|
| **What it is** | Sparkit, Cindercub, Shadelet, Frostclaw (+ the Bramblebun redesign). Complete species definitions — types, base stats, moves, catch rates, placeholder geometry — that **no code path loads**. |
| **Where it lives** | `data/creatures/species_pending.json`. Spawn placements pre-authored in `data/config/spawn_tables.json`'s `_pending` block. |
| **What it would take** | A Meshy generation per creature (owner decision — see §1), then move the entries into `species.json` and the `_pending` rows into `tables`. |
| **How a player meets it** | Nowhere today. Per the `_pending` block: Sparkit in `meadows_open` (rain), Cindercub in `meadows_rock` (band5), Shadelet in `meadows_rock` (night), Frostclaw in `meadows_rock` (band4, rain/fog). |
| **Confidence** | **High** that it is dark. |

**What I actually checked.** `grep -rn "species_pending"` across all `.gd`,
`.json`, `.cfg`, `.godot`: **zero code readers.** The only three hits are prose
inside JSON `_comment` fields. `spawn_tables.json`'s own comment is explicit —
*"NOT LIVE DATA"*. T3-ENCOUNTER's handover §7 item 4 states the reason plainly:

> *"**The pending five are not in the tables.** They are mesh-blocked and
> `smoke_art.gd` rightly refuses a species whose model is not on disk."*

**Two systems ride on this and are dark for the same reason:**

- **The Ice type is entirely inert.** Frostclaw is the only Ice creature
  anywhere. `type_chart.json` declares `ice` and ships four matchup rows for
  it (`fire→ice` 1.25, `ice→ground` 1.25, `ice→fire` 0.80, `water→ice` 0.80)
  that no fight in the game can trigger.
- **Four moves are reachable only from this file:** `shadow_nip`, `arc_lash`,
  `frost_claw`, `glacier_break`. Verified by grepping each id across all
  `.json`/`.gd` excluding `moves.json` — `species_pending.json` is the sole hit
  for each.

---

### E1 — `roll_new_worlds` ships `false`; a whole spawn system is env-var-only

| | |
|---|---|
| **What it is** | Per-world procedural spawn variety. Built, tested (27 tests in `test_spawn_tables.gd`, six deliberate-break verifications), save-migrated to VERSION 14 — and off. |
| **Where it lives** | `data/config/spawn_tables.json` L8. Readers: `scripts/combat/spawn_tables.gd:98`, `autoload/game_state.gd:287,466`. |
| **What it would take** | One boolean — **but there is a recorded precondition, see below.** |
| **How a player meets it** | A new game would roll its own world seed instead of taking `0`. Today every new game gets the byte-identical authored world. |
| **Confidence** | **High.** |

**Listed, deliberately not flipped**, per this lane's brief and per
D-0830-1: the owner wants this ON, and the precondition is that **Gate F
re-baselines first**. Its definition of done is *"`roll_new_worlds: true`, a new
game observably rolls a non-zero seed, an existing save still loads at its
stored seed, the Gate F segments pass against the rolled world"*. T3-ENCOUNTER's
handover §7 names the same coupling: *"flipped with T2-GATEF rather than
underneath it."*

⚠️ **The document recording D-0830-1 is not on `main`** — see **O1**. I read it
at `origin/claude/tetherbound-coordinator-onboard-7pz3ah:ralph/OWNER_DIRECTIVES_2026-08-30.md`.

**`TB_WORLD_SEED` is the only `TB_*` environment variable in the entire
codebase** (verified: `grep -rhoE 'TB_[A-Z0-9_]+'` → 21 hits, all
`TB_WORLD_SEED`), and it is the sole way to reach this shipped functionality
today. That makes it the textbook case of the brief's *"code path gated behind
an environment variable"* category.

---

### T1 — Every trainer, including the Warden, can speak their post-defeat line before being beaten

| | |
|---|---|
| **What it is** | `trainer_npc.gd` picks between the `challenge` and `defeated` conversation using `can_challenge()`, which returns `false` for **four distinct reasons**, only one of which is "already beaten". |
| **Where it lives** | `scripts/world/trainer_npc.gd:172`; `scripts/combat/encounter_director.gd:1699-1706`. |
| **What it would take** | **Not a one-liner** — see below. |
| **How a player meets it** | Faint your lead creature, walk to any of the 27 trainers. The prompt still reads `"Challenge <name>"` (`_prompt_for()` L213-217 is state-independent); activating it plays that trainer's *post-defeat* dialogue and starts no fight. |
| **Confidence** | **High on the code defect. Medium on in-play reachability** — see below. |

`can_challenge()` returns `false` when: the spec/team is empty; a fight is
already running; **`_ally == null or _ally.fainted`**; or the trainer is
already beaten. Line 172 collapses all four into "say the defeated line".

**What I actually checked.** I read both functions. I confirmed a fainted lead
is a real, persistent, *designed* out-of-combat state, not a transient —
`encounter_director.gd:1173` returns a dedicated priority-100 statement
`"<name> is out of the fight."` for exactly it. I confirmed all **27** trainers
in the five `bands/*/trainers.json` carry both a `challenge` and a `defeated`
line, so this always produces wrong dialogue rather than silence.

**What I could not settle without running the game:** whether the interaction
arbiter lets the trainer's prompt fire while that priority-100 statement is
showing. The trainer prompt is an `Interactable` node
(`npc_body.gd::add_prompt`), which is a *different* mechanism from the
director's `prompt_arbiter` offers, so I believe they coexist — but I did not
prove it, and Godot is not installed here. **The confirming test is one
minute of play: faint your lead, walk to any trainer, press interact.**

**Why I did not fix it.** The correct fix needs a third conversation state
("I can't fight you like that") — 27 new dialogue lines, or a prompt-suppression
rule. That is content authoring and a design call, not wiring.

---

## 3. Tier 2 — integration hazards that will *create* dark features

### O1 — The owner's newest directives are stranded on an unmerged branch

**The document that orders this entire install effort is invisible to anyone
working from `main`.**

`ralph/OWNER_DIRECTIVES_2026-08-30.md` exists **only** on
`origin/claude/tetherbound-coordinator-onboard-7pz3ah`. That branch is not an
ancestor of `main`, `ralph/LAND-0830`, or any lane branch I checked. The file
contains **D-0830-1** (roll new worlds, §2 above) and **D-0830-2 — "Install
everything that has been built"**, which is the directive this lane was spawned
from.

Also stranded on that branch alone:

| file | on `main`? | elsewhere? |
|---|---|---|
| `ralph/OWNER_DIRECTIVES_2026-08-30.md` | no | **nowhere else** |
| `docs/decisions/D70-band-5-is-short-on-purpose.md` | no | **nowhere else** |
| `docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md` | no | only `ralph/T1-CREATURE-MESH` |
| `docs/art/reference/creature-expansion-2026-08-30/*` (10 boards) | no | only `ralph/T1-CREATURE-MESH` |

**Why this is a dark-features problem and not just bookkeeping.** Under
`CLAUDE.md`'s precedence rule, explicit newer owner directives outrank
everything. A lane that starts from `main` and reads `ralph/START_HERE.md`
cannot see D-0830-1, D-0830-2, or D70 at all — so the top-precedence document
in the repo is unreachable by the process that is supposed to obey it. This is
the same failure mode as the rest of this report, applied to governance instead
of content.

**What it would take:** land that branch, or cherry-pick the three docs onto
`main`. **Confidence: high** — verified with `git cat-file -e` per file per
branch and `git merge-base --is-ancestor`.

---

### I1 — `T3-SUNSTONE` × `T3-PICKUPS` conflict in `playground_world.gd` silently drops a whole feature

**I hit this myself while building the audit tree, and it cost me a wrong
finding before I caught it.** Recording it because the landing lane will hit it
too.

`ralph/T3-SUNSTONE` was branched **before** `T3-PICKUPS` landed on `main`
(verified: `git merge-base --is-ancestor` → not an ancestor). Both lanes add a
placement call and a placement function to `playground_world.gd`, in the same
two regions:

| | `CACHE_AT` / `_place_item_caches()` | `_place_sunstone()` |
|---|---|---|
| `origin/main` | **present** (5 hits) | absent |
| `origin/ralph/T3-SUNSTONE` | absent | **present** (2 hits) |

The conflict is **100% additive** — no shared logic, no genuine overlap. So a
reflexive `--ours` or `--theirs` resolution *silently deletes an entire shipped
feature* with no test failure to catch it:

- take `--theirs` → **`elixir_might` becomes unobtainable** (D47's permanent
  capped stat booster, and its bespoke `item_cache_pickup.gd`).
- take `--ours` → **the Sunstone never spawns, so Ashtusk becomes
  unreachable** — its wild cluster was deliberately removed from band5
  (`_comment_ashtusk_removed`), leaving evolution as its *only* path.

**What the landing lane must do:** keep both hunks. I verified a union
resolves cleanly and yields `CACHE_AT`=5, `_place_sunstone`=2, zero markers.
The same branch also conflicts on
`data/config/bands/band5_stronghold_approach/spawns.json` (that is the Ashtusk
cluster removal) and `docs/ASSET_LEDGER.md` (T1-CREATURE-MESH).

---

## 4. Tier 3 — dead config, dead code, no player-facing loss today

### B1 — The buff system works and the player is never told

Tonics apply real stat scaling — `creature_instance.gd::apply_buff()` (L570),
`tick_buffs()` (L586), driven from `tab_backpack.gd:1819`,
`playground_hud.gd:3007` and ticked in `game_state.gd:563-571`. But
`data/config/vitals.json`'s entire `buffs` block (`{"max_visible_icons": 3}`)
has **no reader**, and `grep -rn "buff" scripts/ui/` returns only unrelated
`buffer`/`_buffered` hits. **There is no buff indicator in the HUD at all.**
A player drinks a tonic and gets an invisible, untimed effect. Config for a UI
that was never built. *Medium* impact — a feedback gap, not a content gap.

### P1 — Three ROG performance levers are documented as tunable and are not

`data/config/performance.json` ships `collision_stream_radius_m`,
`collision_stream_interval_s`, `collision_stream_cell_m`. **All three have zero
readers** (`grep` for each literal across `.gd` → 0). `vegetation.gd` uses
hardcoded `const COLLISION_STREAM_RADIUS := 100.0` (L199) and
`const COLLISION_STREAM_CELL := 32.0` (L223) — and the doc comment at L220 says
*"Tunable in `data/config/performance.json`"*, **which is false**. Worth more
than its size: these are collision-streaming levers, and the owner's ROG Ally
complaint ("feels like ten frames per second") is the stated reason the file
exists. The sibling `interaction_grid_cell_m` *is* read properly
(`interaction_arbiter.gd:138`), which is the pattern to copy.

### K1 — 15 further config keys with no reader

All verified as zero-hit against production `.gd` **and** `tools/` **and**
`tests/`. Ordered roughly by how player-visible the feature behind them is.

| key | file | note |
|---|---|---|
| `resolve/success_banner` | `catching.json` | catch-success banner duration (2.4s) |
| `buffs/max_visible_icons` | `vitals.json` | see **B1** |
| `menu_creatures` | `input_contexts.json` | an input context nothing enters |
| `reveal_read`, `rise_seconds` | `stronghold_climax.json` | legendary finale timings |
| `spread_deg` | `rift_collapse.json` | |
| `approach_bearing_deg` | `relay_site.json`, `tether_relay.json` | in both files |
| `ramp_steps`, `tether_trim` | `stronghold.json` | |
| `branch` | `burrow_warrens.json` | |
| `blend_sharpness`, `mipmap_bias`, `one_way`, `rejoins` | `terrain_playground.json` | |
| `indoor_position` | `opening.json` | **knowingly parked** — the file's own `_comment_placement` says *"Unused by the live opening since the reversal above"*. Listed for completeness, not as a defect. |

### Z1 — Dead code and orphan assets

- **`autoload/party.gd::all_fainted()` (L205) has zero non-test callers.**
  Confirmed. Its only references are `test_party.gd` and `test_fainting.gd`.
  Notable because a real all-fainted state clearly *can* occur (see **T1**) and
  nothing consults this to handle it — no black-out, no forced return, no
  message. Whether that is a missing feature or a deliberate omission is a
  design question I am not answering.
- **`scenes/world/boot.tscn` — referenced by nothing.** `project.godot`'s
  `run/main_scene` is `scenes/ui/title_screen.tscn`; no `.gd`/`.tscn`/`.cfg`
  mentions `boot.tscn`. The only zero-reference scene in the project; the other
  12 all resolve. Almost certainly an M0-era leftover.
- **Two moves referenced nowhere at all:** `cinder_burst` (fire),
  `mind_ripple` (psychic). Unlike the four in **C1**, these are not even in
  `species_pending.json`.
- **Six orphan meshes** under the audited asset roots:
  `assets/creatures/plumberry/{ernie-the-duck,ollie-the-songbird,bruno-the-bear}.glb`
  and `assets/characters/{Rig_Medium_General,Rig_Medium_MovementBasic,Ranger}.glb`.
  Third-party pack residue rather than Tetherbound work; listed because the
  brief asked for committed assets nothing references. **Not** an install
  target — no player-facing loss, and deleting them is a licensing/ledger
  question for `docs/ASSET_LEDGER.md`, not a wiring one.

---

## 5. Verified reachable — do not re-investigate these

Everything here I expected might be dark and proved is not. Recorded so no
install lane spends a session re-deriving it.

- **All 21 species in `species.json` are reachable.** Built a full
  wild/trainer/table/evolution matrix. **`ripplet` is a near-miss worth
  flagging**: it appears in no spawn table, no trainer team and no band file,
  and a naive audit reports it dark. It is a **starter**, reached through
  `data/config/opening.json`'s `starters.species`. This is exactly the class of
  false positive the brief warned about, and it is why §0's method insists on
  tracing rather than grepping once.
- **All 14 TMs are obtainable** — every one resolves to `trade.json` (sold),
  `playground_world.gd` (placed) or `chapter_rewards.json` (awarded).
- **All 99 conversation ids** across the 11 `data/dialogue/` files are
  referenced.
- **All 7 recipes** and **all 9 buildables** are reachable. `fence` has no
  external reference but `build_menu.gd::_rebuild_catalogue()` iterates the
  whole catalogue, so it is surfaced.
- **The Sunstone → Ashtusk chain is genuinely wired** on `ralph/T3-SUNSTONE`:
  placed in the world (`_place_sunstone`), taken via `KEY_PICKUP` with a
  save-persistent flag, consumed by the evolution, and covered by
  `test_evolution.gd`. **Subject to I1** — it is on the branch, not on `main`.
- **`elixir_might` is obtainable on `main`** via `CACHE_AT` +
  `item_cache_pickup.gd`. I briefly had this as a finding; it was an artifact
  of my own bad conflict resolution, and it is what led me to **I1**.
- **Dual-typing is live for all four variants.** Nightburrow Ground/Dark,
  Stormtrail Ground/Electric, Riftfrill Water/Psychic, Ashtusk Ground/Fire,
  each with a matching new-type move, against a `type_chart.json` that ships
  all 8 types and the full matchup graph. **Their *presentation* is dark
  (D1); their mechanics are not.**
- **The 12 `false` values I first flagged as feature flags are ordinary
  per-entry data** (`aggressive`, `collides`, `casts_shadow`,
  `cleared_by_clearings`). `roll_new_worlds` is the only genuine shipped-off
  feature flag in `data/`.

---

## 6. What I changed

**Nothing.** No code, no data, no config — this report is the only file added.

I was tempted by **D1**: it is 8 JSON keys, the values are already sitting in
the same entries, and it is the highest-impact item here. I left it because
`CLAUDE.md` requires rendered visual-judge evidence for visual-affecting work,
and **Godot is not installed in this container**, so I could not render the
result. Making a change to how four creatures look and pushing it unverified is
the exact failure mode this repo keeps paying for. It is a ~15-minute task for
a lane that can boot the engine.

---

## 7. Suggested order for install lanes

Player impact, not effort:

0. **O1** — do this first and it costs minutes. Until those three docs are on
   `main`, every lane below is working without the owner's top-precedence
   instructions, including the one that ordered this work.
1. **D1** — 8 JSON keys + a render pass. Four creatures stop being reskin-less
   copies. Cheapest high-impact item in the repo right now.
2. **I1** — must be handled *during* the T3-SUNSTONE landing, not after. Get it
   wrong and you delete a feature with no test to catch it.
3. **T1** — needs a design call on the third conversation state first.
4. **E1** — owner-directed ON, blocked on the Gate F re-baseline (D-0830-1).
   Coordinate with T2-GATEF; do not flip it underneath a run.
5. **B1** — build the buff indicator, or delete the config block.
6. **C1** — owner decision on Meshy generations. Not an install task.
7. **P1**, **K1**, **Z1** — cleanup. Either wire the key or delete it; a config
   key with no reader is a lie in a file people trust.

---

## 8. Honest limits of this audit

- **Nothing here was confirmed by running the game.** No Godot in this
  container. Every finding is static analysis: file reads, reference tracing,
  and the lanes' own handovers.
- **T1's in-play reachability is medium confidence**, not high, for the
  arbiter reason given in its entry. The code defect itself is certain.
- **I audited `data/config/*.json` at depth ≤ 3.** Keys nested deeper, or built
  at runtime by string concatenation, could be missed. Dynamically-iterated
  keys were the dominant false-positive source and I excluded them by hand
  (`trade.json` stock, `menu.json` bindings, `palette.json` colours,
  `vegetation.json` asset paths, `spawn_tables.json` table names) — an
  exclusion I made by reading the consuming code, not by pattern.
- **Asset sweep covered `assets/creatures/` and `assets/characters/`** as the
  brief specified. `assets/environment/`, `assets/props/` and
  `assets/buildings/` were **not** swept for orphans and may hold more.
- **`ralph/reports/` coverage**: I grepped all 53 files dated 2026-08-29/30 for
  follow-up admissions and read the handovers behind each finding in full. I
  did not read all 53 end to end.
