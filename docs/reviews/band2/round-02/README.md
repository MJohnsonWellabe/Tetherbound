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

**Critic's verdict:** pending — filling in once the blind pass returns.
