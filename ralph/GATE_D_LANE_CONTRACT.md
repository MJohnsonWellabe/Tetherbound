# Gate D — lane contract (five regional packages, run in parallel)

**Written by the Gate D coordinator, 2026-08-22, from `main` at `a22534ff`.**

Gate D is the five regional Meadows packages, D1–D5, owned by prompts
`62`–`66` in `docs/ralph-prompts/`. They run **concurrently**, one lane per
region, from the start. This file is the cross-lane contract: what each lane
owns, what no lane may touch, and what the coordinator does at integration.

Read it before editing anything. It does not replace `CLAUDE.md`,
`ralph/conventions.md`, `ralph/ACTIVE_GAME_PLAN.md`, or your own band prompt —
it stops five concurrent authors from colliding on the files the A/B/C
consolidation already lost hours to.

## 1. The five packages

| Lane | Band directory | Prompt | Spine reach | `order` range |
|---|---|---|---|---|
| D1 Lower Meadows | `band1_lower_meadows` | `62` | z −512 → 1360 | 1000–1999 |
| D2 Quarry / Warrens | `band2_stone_and_root` | `63` | z 1360 → 3180 | 2000–2999 |
| D3 River / Tether Relay | `band3_the_river_lock` | `64` | z 3180 → 4760 | 3000–3999 |
| D4 Upper Meadows / Ironwood | `band4_upper_meadows_ironwood` | `65` | z 4760 → 7000 | 4000–4999 |
| D5 Stronghold Approach | `band5_stronghold_approach` | `66` | z 7000 → 7680 | 5000–5999 |

`order` is identity, not sort order — `scripts/data/band_content.gd`'s header and
each band file's own `_comment` explain why. **Never renumber an existing entry.**
A new entry takes an unused number inside your band's reserved range, which no
other band can collide with. This is the mechanism that makes five concurrent
regional authors safe; it only works if every lane stays inside its own range.

## 2. Files each lane owns exclusively

Your lane owns `data/config/bands/<your band>/` **whole** — `spawns.json`,
`trainers.json`, `harvest.json`, `props.json`, `vegetation.json` (create it if
your band has none). No other lane touches it.

Your lane also owns the site configs that exist only inside your region:

- D2 — `data/config/old_quarry.json`, `data/config/burrow_warrens.json`
- D3 — `data/config/relay_site.json`, `data/config/tether_relay.json`
- D5 — `data/config/stronghold.json` **exterior/approach keys only**

D5: `data/config/stronghold_climax.json` and the Warden/legendary/release
content are **Gate E**, prompt `69`. D5 ends at Hall entry. Do not author the
finale.

Tests: a new `tests/test_*.gd` file named for your band is yours. Editing an
existing shared test file is allowed only when your content genuinely breaks its
assertion, and then say so loudly in your report.

## 3. Files NO lane may edit

These are global and shared across every region. Editing them concurrently is
the single biggest collision risk in Gate D, and two of them force an
unparallelizable re-bake:

- `data/config/vegetation.json` — scatter rules, layers, `retint`, and the
  per-band `corridor_bands[].density_scale`
- `data/config/terrain_playground.json` — heightfield, trail spine, crossings,
  river, paths
- `data/scatter/playground/**` — the baked scatter itself

**Chosen policy for this run: option (b) — no lane edits them at all.** Every
regional package is expressed entirely through band-scoped config. This is not a
compromise: spawns, trainers, harvest nodes, prop clusters and clearings are all
already band-scoped, and that covers what prompts `62`–`66` actually ask for.

The reason is cost, not caution. `scripts/world/bake_playground_scatter.gd` is a
~60-second single-threaded pass over the whole corridor, and two lanes baking
against two different configs produce two conflicting `data/scatter/playground/`
trees that cannot be merged, only re-run. Serializing five lanes behind one bake
would remove the parallelism this run exists for.

**If your region is too bare and you believe it needs more scatter**, do not edit
the file. Report a requested `density_scale` for your band (current values:
band1 0.07, band2 0.05, bands 3–5 0.03) with your reasoning. The coordinator
applies all five requests in **one** edit and runs **one** bake at integration,
followed by `tests/smoke_traversal.gd`. That is option (a), held by the
coordinator and narrowed to the one key that needs it.

Also coordinator-owned — do not edit, report what you want instead:

- `data/config/chapter_curve.json` — the authority for your band's wild levels,
  trainer levels and expected team. Author **to** it; never edit it to fit
  content you wrote. `tests/test_chapter_curve.gd` enforces the ordering.
- `data/config/chapter_rewards.json`, `data/config/progression.json`
- `data/config/spawns.json`, `trainers.json`, `harvest.json`, `props.json`
  (the *head* files — they hold only the non-positional keys now; your content
  goes in your band directory)

Two shared files accept **append-only** edits, because the alternative is
routing every region's navigation and objectives through the coordinator:

- `data/config/map_landmarks.json` — append to the end of `landmarks` /
  `regions`. Never reorder or renumber existing entries.
- `data/progression/objectives.json` — append to `local` only, with ids
  prefixed by your band (`band3_...`). The twelve-beat `main` chain is settled
  by prompt `68`; do not restructure it.

Expect a trivial textual conflict on those two if two lanes append in the same
window. The coordinator resolves it by keeping both blocks. That is the whole
cost, and it is much smaller than the bake.

## 4. Known defect every lane inherits

`scripts/world/scatter_bake.gd::config_fingerprint()` hashes only the head
`vegetation.json` and `terrain_playground.json`. It does **not** hash
`data/config/bands/<band>/vegetation.json`, even though
`scripts/world/scatter_rules.gd::config()` merges those files' `clearings` and
`footprints` into the placement pass. So a band clearing you add changes where
scatter should go and does **not** invalidate the bake — the stale bake is
served silently, and your camp stays buried in grass.

Do not fix this yourself; five lanes fixing one file is the collision this
document exists to prevent. **The coordinator fixes the fingerprint and runs the
single re-bake at integration.** Add your clearings normally and note in your
report that you added them.

## 5. What "finished region" means here

Not "the JSON has entries." `tools/_probe_chapter_map.py` prints the current
counted content map per band; run it before and after and put both in your
report. The baseline at `a22534ff`:

| Band | spine | trainers | wild clusters (creatures) | gatherables | prop clusters |
|---|---|---|---|---|---|
| 1 | 1872 m | 8 | 8 (16) | 14 | 4 |
| 2 | 1820 m | 2 | 6 (9) | 17 | 2 |
| 3 | 1580 m | 5 | 8 (18) | **0** | **0** |
| 4 | 2240 m | 2 | 8 (18) | **0** | **0** |
| 5 |  680 m | 4 | 4 (9) | **0** | **0** |

Bands 3, 4 and 5 have no authored gatherables and no prop clusters at all — the
back half of the chapter has nothing to pick up and nothing built in it. Band 2
and Band 4 have two trainers each. Band 4 is the longest region in the chapter
and its wild population is the thinnest per metre. Those are the shapes of the
gaps; your prompt names the content that fills them.

Counts are a floor, not the goal. The acceptance in prompts `62`–`66` is about
cadence: regular but non-uniform reasons to stop, no long stretch of purposeless
running, and at least one optional thing that competes with direct progress.

## 6. Hard rules, restated because content authoring is where they get broken

- **Five creatures, ever.** No storage, no reserve, no sixth slot.
- The human **never fights**; no human weapons.
- Combat is real-time and piloted. **No shields, no dodge.**
- **Trainer-owned creatures cannot be caught** — a special encounter you author
  must be a wild if you want it catchable.
- No hunting or butchering. Food buffs; there is no starvation death.
- **No new creature meshes and no Meshy generations.** Differentiate with
  materials, scale, animation, VFX, habitat, behaviour and encounter context.
  Not one generation without owner-supplied reference art.
- **Reuse the six installed humanoid rigs** — trainer, Grandpa, Warden, villager
  male, villager female, Team Tether grunt. `docs/art/HUMANOID_ASSET_INVENTORY.md`
  is authoritative. A new named trainer is a per-material variant of an existing
  rig, never a new mesh.
- One nature family, one village family, one prop family. A prop cluster uses
  models the settlement already uses.
- **No Biome 2.** Any reconnection view is distant and non-enterable.
- **Do not silently invent a major gameplay/story decision.** A new named
  character with real story weight, a new mechanic, a new type interaction, a
  change to the five-creature cap or the evolution rules — flag it in your
  report per `CLAUDE.md`'s "Ask instead of inventing" list and author around it.
  Siting a picket, a camp, a herd or a gatherable is ordinary work, not
  invention.

## 7. Verification each lane owes

1. `tools/_probe_chapter_map.py` before and after.
2. The data tests your change touches, run locally and green:
   `test_band_content.gd`, `test_band_vegetation.gd`, `test_spawns_data.gd`,
   `test_trainers_data.gd`, `test_chapter_curve.gd`, `test_chapter_content_map.gd`,
   `test_harvest.gd`, plus `smoke_art.gd` for anything touching creature data.
   Run the whole unit suite if you changed anything an autoload reads.
3. A **real driven run through your region**, not only unit tests — the smoke
   test that covers your region (`smoke_warrens.gd`, `smoke_relay.gd`,
   `smoke_relay_station.gd`, `smoke_stronghold.gd`, `smoke_traversal.gd`), or a
   purpose-built capture/probe under `tools/` if none fits. Record what the run
   actually showed: encounter cadence, the longest dead-travel interval in
   metres, and whether the region's objective is legible while playing it.
4. Anything visually load-bearing gets the blind pass from
   `ralph/conventions.md` §"Visual-affecting work needs a blind pass" — render
   real frames, run `.claude/skills/visual-judge`, iterate to convergence, and
   record the round count and what the last two rounds failed to move. Do not
   grade your own frames.
5. A short written record of what you found and decided, in the repo, in the
   voice the codebase already uses: explain *why*, name the failure it prevents,
   be honest about what is not built.

## 8. Branch and ship protocol

- Work in your own worktree on `ralph/gate-d-band<N>-<slug>`. Push it when it is
  green. `ci.yml` runs on `ralph/**`; that CI run is your proof.
- **Pushing is not shipping.** `ralph-merge.yml` and `ralph-sweep.yml` are
  `workflow_dispatch` only. Nothing lands on `main` by itself. Do not dispatch
  them — integration is the coordinator's job.
- Never push to `main`. Never force-push a branch another lane is on.
- If `main` moves under you, rebase your branch on it and push again.
- `ralph/DONE.md` has one insertion point right after its 4-line header and is a
  known concurrent-rebase conflict. Keep your bookkeeping entry small and expect
  to resolve it; keep both `##` entries, yours after the one already there.

The coordinator merges all five onto `ralph/integration-D`, applies the
`density_scale` requests, fixes the scatter fingerprint, runs the single re-bake
and the full suite, and dispatches the consolidation run.
