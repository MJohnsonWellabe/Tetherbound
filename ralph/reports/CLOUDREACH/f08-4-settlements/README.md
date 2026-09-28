# F08#4 — settlements and cliff identity (Phase 1: function and readability)

Criterion (ACCEPTANCE §6.1 F08): "The correct high-perch camera, settlements and cliff identity pass C2's
visual matrix." Phase 1 (STATE §1 ruling 4): closes on function — each settlement is occupied and reads as
its place from the approach (people, activity, navigable layout); cliffs read as routes and landmarks.
**Bars A/B → Phase 2 catalog.** Codex's Cloudreach towers and occupied terrace stay off (not needed for function).

## Game changes (tb/cloudreach)
- **Residents.** Galefoot and Cliffhold each have two working residents from the first visit (the existing
  world-payoff traveler patrol: `data/config/cloudreach_npc_runtime.json` `world_payoffs.travelers`,
  `data/dialogue/cloudreach.json`). Galefoot: a carter along the yard's south side, a mender beside the
  arrival lane. Cliffhold: a porter carrying in from the east arrival road, a ropewright beside the road's
  mouth. Every loop keeps 0.6 m clear of the engine-measured cottage footprints
  (`tests/test_cloudreach_cast_dialogue.gd`); occupancy on first visit is tested there too.
- **Settlement ambience.** The second centre sat on Tavi's ring 690 m from Cliffhold; it now sits on Cliffhold
  (`data/config/cloudreach_atmosphere.json`, `tests/test_cloudreach_atmosphere.gd`).
- **Broken Causeways crown carve.** `broken_causeway_main` climbed inside the region's drawn crown for its last
  ~100 m (road vanished into a grass wall; crown grass floated overhead). The region now takes the summit's
  existing `crown_cut` (`data/config/cloudreach_world.json`).

## Evidence
- `r0/` — baseline (before), 13 frames.
- `r1/` — the frame matrix, rows 1-35 day plus night rows 30-32, galecrest out (`tools/capture_cloudreach_frame_matrix.gd`).
  Rows 05/25/36/37 were removed here (they predate the resident moves); rows 16 and 18 are capture-stand
  defects (a camera inside the needle ring; a shrine stand seated on the lower ground facing rock) and were
  not judged; High Roost is covered by 15, 17, 19, 20 and the F08#3 r5 glide frames.
- `r1c/` — Galefoot rows 05, 36, 37 day and 05, 37 night with terrapup out (the earned five carry no flier).
- `r1d/` — Cliffhold row 25 day and night from a 30 m stand on the east road.
- `r1f/` — Broken Causeways rows 06-10 and night 31 after the carve.
- Judges: `r1/judge-prompt.md` → `r1/verdict-r1.md` (A PASS, B FAIL, C PASS); after the carve,
  `r1/judge-prompt-r2.md` → `r1/verdict-r2.md` (B PASS, C PASS).

## Disclosed shortcuts
Fixture start (`reset_for_new_game`, Act I-II flags, party added directly, scene instantiated directly);
teleport to each stand; the clock pinned; HUD hidden; the settlement rows use `--active=terrapup`; two stand
changes after judge 1 (row 37 from 57 m to 36 m out, rows 07/31 onto the centreline at t=0.6); the second
judge was told that High Roost has no walking road by design; frames stored as JPG; stills, not video.

## Recorded, not blocking (Phase 2 or later)
Cliffhold reads PARTLY (thin occupation, no hearth seen, same cottage/tower kit as Galefoot, few night
lights); the companion fills the frame on the rope bridge (09) and at the aviary (29); High Roost's reverse
(17) and rim views show no next landing; 14 frames no beacon; 26 frames a cliff wall.
