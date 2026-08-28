# Coordination — 2026-08-27 — post-Phase-B plan

Owner directives, 2026-08-27, in order given:
1. everything on `main`, including the grass;
2. deploy to the website so the owner can download and play;
3. stop Gate F, fix the rig, re-run;
4. "don't stop anymore. do what you think is right."

## What Phase B established

`ralph/reports/gate-f-phase-b/`, candidate `f082bdf6`.

**Capture rate 8.0% — 13 of 162 player-facing historical items found
independently.** Per §16.5 the historical backlog therefore **remains
operationally authoritative**; the Gate F backlog is additive, not a
replacement. The original goal — regenerate the backlog from evidence — is
NOT met, and must not be reported as met.

**Three of the four loudest findings are harness artifacts**, refuted by the
run's own data: "input ownership never handed back", "no fight ever stages",
and the 23-minute `SwapPanel` hold. The South Bridge genuinely never opens —
because its gate fight was never won, which is a gate working correctly.

The adjudication gate placed on Phase B before it wrote anything is what
caught this. Without it the backlog would have been rebuilt out of
instrumentation bugs.

## Tier 0 — the rig (blocks a meaningful re-run)

| id | what |
|---|---|
| `GF-B-002` | Three primitives close ~120 of 202 journey FAILs, all 118 X01, all 21 X02: assert-context-before-proceeding, `advance_dialogue_until_closed`, `move_to_entity` |
| `GF-B-003` | No prescribed screenshot exists anywhere in the run. `shots/` never existed; 9,231 manifest rows written `file: null`; capture steps returned PASS having produced nothing |
| `GF-B-011` | 13 telemetry event types are never emitted, so the schema cannot evidence itself |

Protocol changes that must travel with the fix (CD-1, CD-2): a capture that
cannot be taken is a **FAIL**; a segment that can take none of its planned
captures is a **BLOCKER at step 1**; the §M inventory check runs as code and
commits an `INVENTORY.json`.

## Tier 1 — real game defects, parallel to Tier 0

| id | what | note |
|---|---|---|
| `GF-B-004/008/010` | black sphere in the Hall arch; The Rise renders black; NPC unlit in daylight | **Do the sun-azimuth check FIRST.** `HIST-052` records the sun placed in the NORTH sky, never re-checked. One number may close all three |
| `GF-B-001` | ~50 s frozen screen on New Game, 49,230–50,720 ms in 6 of 8 segments, renderer OFF | Suspect is the scatter/placement bake (`HIST-085`). NOTE: grass-on suppresses 625,227 baked placements and adds a runtime field — this may move the number in either direction |
| `GF-B-005/006` | quickbar shows d-pad badges not contents; roster block over centre screen | Same file; sequence together. Unblocks `HIST-036` |

## Sequencing

1. Land `ralph/GRASS-ON` (grass + CI/import consolidation) — CI 2557.
2. Sweep every green `ralph/**` to `main`.
3. Dispatch `release.yml` against `main` ONLY. Verify by asset timestamp + head_sha, never the release body prose (hardcoded at `release.yml:150`).
4. Open the rig lane and the defects lane in parallel.
5. Re-freeze a NEW candidate only after both land. Do not re-run against `f082bdf6`.

## Standing constraints carried forward

- Never push `main`; ship via `ralph/<task>` + dispatched sweep; no PRs.
- The sweep takes no branch argument: it lands and DELETES every green `ralph/**`. Know the full set before dispatching.
- Merge `main` forward, never rebase — a scatter re-bake cannot be rebased (binary conflict).
- [OWNER-ONLY], never claimed from this container: device frame rate, GPU, VRAM, thermals, controller feel, audio, Windows export identity.
- Do not check out branches while a Godot capture is running.

## Coordinator finding, 2026-08-27 — the sun hypothesis is DEAD for GF-B-010

Captured independently on `ralph/GRASS-ON` via `tools/_probe_grass_pass.gd`
(14 frames, four bands plus mounted, grass field ON).

**`GF-B-010` (NPC renders as an unlit silhouette in daylight) reproduces**, in
two different bands, at two different sites: `02-band2-forest-floor-off.png` and
`04-band4-high-pasture-eye.png`. Phase B rated it MEDIUM confidence off a single
frame; it is now confirmed on a different branch, at different locations.

**And it rules out the proposed common cause.** `SUMMARIES.md` RC-5 proposes
checking `art.json`'s sun azimuth first, on the theory that a north sun leaves
approach geometry unlit and would close `GF-B-004`, `GF-B-008` and `GF-B-010`
together. That cannot be the mechanism here: **in the same frame, lit by the same
sun, the grass, trees, terrain and the PLAYER'S OWN MODEL all shade correctly.**
The player stands about a metre from a jet-black NPC with visible fabric folds
and a lit satchel. A misplaced sun cannot light one character and not another.

So `GF-B-010` is specific to those NPC materials, not to scene lighting. Start
there, not at the sun.

Two further notes on RC-5 from the same frames:

- **`GF-B-004` (black placeholder sphere in the Hall arch) is very unlikely to be
  lighting at all.** A black sphere at a gateway reads as a missing mesh or an
  unassigned material. Do not spend the lighting diagnostic on it.
- The sun geometry was checked anyway and is worth recording so nobody re-derives
  it: day is `pitch_deg -44`, `yaw_deg 140`, applied as
  `sun.rotation = Vector3(pitch, yaw, 0)` (`world_look.gd:335`). Light direction
  works out to roughly `(-0.462, -0.695, +0.551)`, so the sun sits toward +X/-Z —
  the northern sky, as `HIST-052` says. But the chapter runs from the village at
  z ~ -10 to the stronghold at z ~ +7595, so the player travels **+Z** and sees
  the **-Z-facing** faces of what they approach — which a -Z sun **lights**. The
  azimuth is northerly; the inference drawn from it does not follow.

**`GF-B-013` (signpost text does not read) also reproduces**, clearly, in
`04-band4-high-pasture-eye.png`. Raise its confidence.

Not findings, recorded so they are not chased: three `WARN no collision under
(...)` lines during the capture are the probe teleporting between distant bands
before terrain streams in, and are a property of how the tool travels rather than
how a player does. And every frame is llvmpipe software rasterisation —
composition, density and silhouette are trustworthy, frame times are not.

## CORRECTION to CD-2, from the operator's stand-down — the frames EXIST

Check-in 30 on `ralph/reports/gate-f-lane-log.md`, written after the stop order.
**Read this before doing any CD-2 work; the rig lane's brief was issued with the
wrong diagnosis.**

CD-2 states that no `shots/` directory exists anywhere in the run and that X07's
79 artefacts "do not exist on disk". **That is wrong.** `shots/` existed in every
segment; X07's held 79 real 1920x1080 PNGs, about 1.5 MB each, 134 MB total. The
operator decoded their pixels — check-in 28's colour verification was a
from-scratch PNG decode over all 79, not a manifest read.

What is true is that **git carried none of them**, and the cause is one line:

    $ git check-ignore -v .../X07/shots/GF-14-COMBAT-13b.png
    .gitignore:34:shots/    .../X07/shots/GF-14-COMBAT-13b.png

`.gitignore:34` is a bare `shots/` written for `tools/survey.sh` output. **A bare
directory pattern matches at any depth**, so it swallows every Gate F segment's
own `shots/` — this run and every previous one. And `git add <dir>` skips ignored
contents **silently**, so fourteen per-segment commits looked like they worked.

**This changes the fix.** CD-2's remedy was written as "the harness never wrote
the files"; the real remedy is an ignore rule scoped to the survey output rather
than matching at any depth, plus an inventory check that would have caught the
silent skip. The inventory check is still needed — it is what turns a silent
`git add` no-op into a failure — but the harness's capture path is not the
defect it was thought to be.

CD-1 is unaffected: segments genuinely ran without a display server, and capture
steps genuinely returned PASS having produced nothing. Both remain true.

**Coordinator's own miss, recorded so the pattern is visible.** While capturing
the grass frames I ran `git check-ignore` on my own output and got this exact
line back, `.gitignore:34:shots/`, and read it as correct behaviour for a
scratch render directory. It is correct for that. I did not connect it to Gate F's
missing evidence, which was sitting in the same session's context. The operator,
who had the files on disk, did. Two correct local readings, one missed
system-level consequence.

## Evening corrections — two of my own claims, and a Phase B item that survives

### GF-B-004 is a REAL game defect. My "five were the instrument" was wrong.

I relayed the defects lane's scene-graph audit — *"THE SPHERE IS NOT THERE"*, no
floating object above the stronghold, no surface with a missing material — and
concluded that `GF-B-004` and `GF-B-008` were both rig artefacts, making five of
Phase B's loudest findings the instrument's.

**The rig lane checked it against the recovered frames and the count is four.**
`GF-AUD-hall-gameplay.png` is a clean, well-lit exterior of the stronghold gate:
mean luma 72.8, spread 43.2, 2.4% of the frame below luma 24, player in front,
HUD legible — **and the black sphere is plainly visible in the archway.** The
camera is not buried. `GF-B-004` stays a game defect and needs an owner for it.

Why the audit missed it: it enumerated `MeshInstance3D` surfaces and the sphere
is presumably not one, which the defects lane itself flagged as a limit of the
method ("does not rule out non-MeshInstance3D geometry, or a sky artefact"). I
dropped that caveat when I relayed it. The lesson is the one this whole day keeps
teaching: a negative from an instrument is only as strong as what the instrument
can see.

### GF-B-008 IS a rig artefact — but not for the reason given

All six `the_rise` frames were taken at the SAME camera position,
`[88.0, 2.22, -43.0]`, with only yaw varying. Four are wide, fully-lit vistas
(`the_rise-landmark` is mean luma 111.9). **A camera inside solid geometry is
black at every yaw**, so it is not buried; at two of six yaws the near field is
filled by something opaque. The proposed "refuse if the camera is inside
collision geometry" check would have answered a question neither frame was
asking.

The rig lane's fix is better than the one I would have specified: gate on the
IMAGE, not the camera. Every prescribed capture now carries mean luminance,
spread and dark fraction on its manifest row, and a frame both very dark and
very flat fails. Calibrated against the 79 recovered frames, and the separation
is not the obvious one — **mean luminance does not work**, because the two
darkest frames in the set are legitimate night captures:

    the_pond-night-gameplay   mean 25.1  stddev 41.1  frac<24 0.584  LEGITIMATE
    the_rise-gameplay         mean 26.6  stddev 29.0  frac<24 0.755  degenerate

A night scene is dark and keeps its contrast; an obstruction is flat. Both
conditions are required, and this repo's own title screen proves why: mean 50.8,
spread 32.4 — its spread is below the gate, being a deliberately flat dark UI,
and only the dark-fraction half saves it from being discarded as broken.

### Also worth knowing for whoever re-transcribes X07

The six `hall` captures were taken with `region=corridor` while step X07-165
asserts `region_is == hall`. That assertion failed and the captures went ahead
anyway, filed under the name `hall`. Not a rig bug — §1.6 says an ordinary failed
assert is a verdict on the game and the run continues — but a capture named for a
place the run has just measured itself not to be in is worth attention.
