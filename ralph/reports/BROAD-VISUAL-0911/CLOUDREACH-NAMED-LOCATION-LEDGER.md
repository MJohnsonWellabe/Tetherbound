# Cloudreach Named-Location Visual Ledger — 2026-09-11

This is the authoritative working ledger for the Cloudreach named-location lane
on `codex/cloudreach-visual-quality-0911`, derived from
`data/config/cloudreach_world.json` and the retained evidence described in
`docs/HANDOFF_BROAD_VISUALS_2026-09-10.md`.

Strict meanings:

- **PASS** — blind, production day/night evidence meets the commercial reference bar.
- **POLISH** — readable retained work, but not yet independently certified at that bar.
- **FAIL** — invalid evidence, weak/incorrect identity, or a blind commercial-bar failure.

No named Cloudreach location is currently certified as a strict PASS.

| # | Authoritative named location | Current disposition | Evidence / next boundary |
|---:|---|---|---|
| 1 | Realm Gate Crag | POLISH | Dedicated retained presentation; latest handoff records strong KEEP/POLISH, not a hard commercial pass. |
| 2 | Galefoot Waycamp | POLISH | Dedicated retained presentation; readable but still judged as a generic settlement. |
| 3 | Three Bells Bridge | POLISH | Dedicated retained portal and three readable bells; still a KEEP/POLISH result. |
| 4 | Broken Skyroad Arch | FAIL (improved, blocked) | This checkpoint replaces the primitive slabs, narrows the ledge into a severed road, authors a fractured arch/suspended remnants, clears the central cover route, and adds night separation. Blind readiness improved from 2/10 baseline to 5/10, but remained FAIL. See blocker below. |
| 5 | Windscar Beacon | POLISH | Retained open-beacon composition; readable, but prior review did not certify the commercial bar. |
| 6 | Windscar Flight Aerie | FAIL | Baseline requires restaging. |
| 7 | Sky Shrine | FAIL | Latest baseline evidence is invalid. |
| 8 | The High Perches | FAIL | Prior prop-level candidates produced no independent commercial gain; requires a larger composition pass. |
| 9 | Cliffhold | POLISH | Baseline KEEP/scene-polish; no strict blind PASS recorded. |
| 10 | Old Wind Observatory | FAIL | Latest baseline is partial. |
| 11 | Summit Eyrie | FAIL | Latest baseline is partial. |
| 12 | Stormward Overlook | FAIL | Latest baseline evidence is invalid; canonical display name retained although the internal id is `waterward_overlook`. |

## Broken Skyroad Arch retained evidence

- Baseline day/night:
  `shots/locations/cloudreach-broken-skyroad-arch-0911-baseline/`
- Retained production day/night:
  `shots/locations/cloudreach-broken-skyroad-arch-0911-candidate-r7/`
- Production catalogue result: `2/2` frames.
- Focused regression result: `24` tests, `1,477` assertions, `0` failures.
- Blind rounds:
  - primitive baseline versus authored intact gate: `2/10 FAIL` versus `4/10 FAIL`;
  - intact gate versus fractured object pass: `3/10 FAIL` versus `4/10 FAIL`;
  - fractured object pass versus narrowed-ledged/cleared-route pass: `4/10 FAIL` versus `5/10 FAIL`.

### Specific blocker

The installed castle kit can establish a readable arch and masonry family, but
three independent blind reviews still identify its visibly modular fracture
planes, repetitive material treatment and lack of a bespoke collapsed-skyroad
mesh as the remaining landmark-level commercial blocker. The other repeated
defects are inherited global presentation systems: oversized procedural cover,
the region/tutorial overlay masking the crown, and Cloudreach exposure/night
grading. `docs/CLOUDREACH-GRASS-DISPOSITION.md` explicitly stops further grass
mechanism trials after repeated no-yield runs, while the global UI/exposure
systems affect every named location and require a separate measured systemic
lane rather than an unbounded local tweak. The retained checkpoint therefore
records an evidence-backed improvement, not a false PASS.
