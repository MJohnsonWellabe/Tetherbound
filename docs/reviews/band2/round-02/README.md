# Band 2 (Stone & Root) — round 2

**What changed since round 1.** Round 1's Bar A/B were both No, and its top
gaps were: named locations (camp, quarry) reading as empty because they were
shot from 85-110m away; a pylon conduit reading as a "wireframe" for the same
distance reason; world density and night lighting, both real but out of this
band's own scope right now. This round only changes the *camera* — no new
content, no data/lighting edits:

- Added a close quarry-station shot (`02b`) alongside the original overlook
  vista (`02a`).
- Moved the ranger-camp day/night shots from ~85m to ~10m — the same distance
  `tools/capture_ranger_camp.gd` already proved legible for this cluster.
- Retargeted the "late ridge" shot onto an actual authored harvest node
  instead of an arbitrary spine point.
- Moved the early-forest shot from ~86m to ~39m of the trailpup spawn.
- Tried moving the "parked" (out-of-shot) trainer body further away to test
  whether it was causing an unexplained shadow artefact round 1's critic
  named in three frames — **this did not fix it**; the shape is still
  present in `02a` after the change, so that hypothesis was wrong. Left
  investigating, not fixed.

Deliberately **not** touched: `vegetation.json` density (still
`HARVEST-ALL`'s table) and the night lighting preset (still a global,
not-Band-2-specific question). Both are still visibly true in this round's
frames (05 is still mostly bare; 06/07 are still close to black even at 10m).

**Critic's verdict, in its own words.** Bar A: still **No**. Bar B: still
**No**. But this round shows real movement, not a flat repeat — the stopping
rule (`ralph/conventions.md`) counts a round as improvement if the critic
names something new OR a previously-named defect resolves, and both happened:

- **A previously-named defect resolved, and the critic said so unprompted**:
  round 1 called the trainer "a 4-5px blur... not readable as a person";
  round 2 says frame 01 is "the one frame where the character-as-ruler trick
  actually works." Direct result of moving that eye from ~86m to ~39m.
- **02b (the new close quarry shot) is called out as the strongest frame in
  the set** — "best-reading frame... at 40%," "the one frame that reads as
  composed rather than scattered," "the closest thing to authored in the
  set."
- **New defects only visible at close range, impossible to name in round 1's
  distant shots**: the quarry's own rootstone deposits read as "a pale mint/
  seafoam... hatch-patterned surface" that "doesn't read as stone at all";
  the Warrens' wall geometry is "completely flat-shaded... no texture... it
  looks like unfinished blockout geometry"; the ranger camp's props read as
  "three props dropped at a way-point, not a camp anyone lives in" (a sharper
  version of round 1's "no camp objects," now that the objects are actually
  visible to judge).

Top three gaps this round: (1) night frames "essentially solid black... does
not read as night, it reads as unlit"; (2) 01/03/05 still "80-95% flat,
undetailed grass with one small isolated point of interest"; (3) material/
palette breaks at the two close landmark shots — the mint-coloured boulders
and the untextured Warrens wall.

Full text on `ralph-status`/`ralph/NOTES.md`. Round 3: one small, in-scope
attempt (bulking the ranger camp cluster with more of the same prop family)
before stepping back to assess how much of what's left is actually outside
this band's own file ownership.
