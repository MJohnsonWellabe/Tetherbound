# START D3 — River / Tether Relay

**Branch:** `ralph/gate-d-band3-river-relay`
**Band directory:** `data/config/bands/band3_the_river_lock/` — yours whole
**Also yours:** `data/config/relay_site.json`, `data/config/tether_relay.json`
**Reserved `order` range:** 3000–3999
**Owning prompt:** `docs/ralph-prompts/64-BAND3-finished-river-relay.md`
**Spine:** z 3180 → 4760, ~1580 m. The river gorge runs east–west at z≈4200,
10–15 m deep, narrowing to a 3.6 m half-width at the Old Mill Crossing. The
Tether Relay Station sits at z≈3760.

Read `ralph/lanes/COMMON.md` first, then `ralph/GATE_D_LANE_CONTRACT.md`, then
your prompt, then `ralph/DONE.md`'s band3 entries.

The region's question: **what is Team Tether actually doing here, and can my
team beat them directly?** Prompt 64's definition of done: *crossing the
restored river feels earned because the player has defeated a real local Team
Tether operation and the world physically responded.*

## Already done on this branch — do not redo it

Three commits pushed. Full suite green: **1301 tests, 715473 assertions,
0 failed**, run in the foreground.

- **Density**: 8 clusters / 18 creatures → **50 clusters / 155 creatures**,
  inside the owner's 38–50 / 140–210 target. **Density is done.** The original
  habitat logic was kept and 41 clusters added on the same rules — air species
  owning the gorge, water species at the crossing where the water is reachable,
  ground species on the relay's spoil.
- **Gatherables 0 → 12** (`harvest.json`): wood/stone/fiber/berries spread the
  full 1580 m. The region had nothing to pick up before this.
- **Prop clusters 0 → 4**: a rest/staging spot on the flattest ground measured
  in the band, a Team Tether checkpoint (no trainer) before the pickets, the
  relay yard clutter `tether_relay.json` had explicitly been waiting for, and
  gear at the Old Mill Crossing.
- **Picket redesign** — the fix prompt 64 names by name. Hess and Orrin moved
  off the compact 26 m site radius onto the actual spine road (roughly 140 m and
  70 m out), so Team Tether presence now builds *before* the compact Dell/Vance
  assault instead of all four landing in one 18 m span. Vance is unchanged; his
  position gates the rescue.
- **Camp siting**: one new clearing in a new band `vegetation.json`.
- **Optional content**: a second wild cluster on the already-authored
  `near_bank_river_walk` detour loop, which previously had nothing on it.
- Cadence, analytical probe against the real spine: longest dead-travel gap
  **81 m**, at the region's own north exit into Band 4. River crossing zone
  (z 3980–4260) holds 32 wild creatures and 0 trainers — ecology is not erased
  by faction content.
- `tests/smoke_relay.gd` and `tests/smoke_relay_station.gd` both pass against the
  new picket positions; the rescue/console/crossing chain was already correct on
  `main` and needed no changes.

## Test edits already made, with reasons — leave them

- `tests/test_trainers_data.gd`'s site-radius check split into a strict compound
  bound and a generous approach bound. The old check enforced exactly the
  clustering prompt 64 asks you to fix.
- `tests/test_band_vegetation.gd`'s exact-size fixture check relaxed to `>=`,
  matching its own sibling test's tolerance for legitimate post-split growth.
  Three lanes made this change; the coordinator collapses the overlap.

## What is left

1. **A real blind visual pass.** Six frames were rendered but judged by the lane
   itself against the reference boards, which `ralph/conventions.md` forbids and
   which the previous round recorded honestly as a lesser substitute. Re-render
   if needed, then **ask the coordinator to dispatch the independent critic**.
   Self-judged findings to re-test blind: density reads sparse against both
   references; the relay wall shows no visible oxblood accent from one angle;
   the mill-crossing frame is framed too wide.
2. **A played driven run.** The cadence numbers above are analytical. What is
   missing is evidence from actually moving through: whether the river is
   understandable as geography, whether the Team Tether escalation reads, and
   whether the objective is legible while playing.
3. Prompt 64's remaining acceptance items to verify rather than assume: Captain
   Vance feeling like the end of a mini-stronghold rather than a bigger trainer,
   and the rescue physically changing what the player can do.

## Two capture-tool bugs you found and fixed — and one you did not

Fixed in your own tools: the day/weather clock racing the multi-viewpoint pass,
and parking the camera rig's player underground tripping the water-hazard
warning overlay.

**Not fixed elsewhere**: the same conventions exist in other capture tools
(`capture_prop_clusters.gd` and friends). You recorded this as outside band3's
ownership, which was right. It is now relevant beyond your lane — D1's campfire
appears to render embers but no flame, glow or smoke in captures, which looks
like exactly this class of bug. If you have cheap insight into that, tell the
coordinator; do not go fix D1's lane yourself.

## Already handled — do not spend time on it

You reported `smoke_art.gd` failing globally regardless of content. You were
right: it fails on pristine `main` at `a22534ff` with eleven failures. The
coordinator root-caused it (both checks looked for scattered props as named
scene children of `Vegetation`, and there have been none since the scatter moved
to `Terrain3DInstancer`) and fixed it on `ralph/integration-D`, along with
wiring `smoke_art.gd` into CI, which had never run it at all. Ignore those
eleven failures on your branch.

## No `density_scale` request was made

The previous round judged existing band3 content already ships at the 0.03 floor
and did not think it worth asking the coordinator to touch a shared file.
Revisit only if the blind pass says the region reads bare — and **report a
number, do not edit `vegetation.json`.**
