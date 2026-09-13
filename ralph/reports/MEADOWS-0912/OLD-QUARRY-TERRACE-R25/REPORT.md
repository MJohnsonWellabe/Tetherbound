# The Old Quarry R25 — independent named-location verdict

## Verdict: FAIL — do not promote R25

I reviewed `manifest.json` and all eight 1280×800 production PNGs at native
resolution, alongside the binding Meadows key art and Palworld references. I also
used R19's last complete POLISH verdict and the R20/R21 evidence failures as regression
context. I did not inspect source or run Godot.

R25 fixes evidence completeness: all eight required frames exist, the manifest reports
`complete: true` with no failures, and every player seat is grounded. The pixels do not
clear the named-location gate. The large grey subject is immediately visible, but it
reads as a freestanding bunker or ruin wall assembled from rectangular slabs. Its dark
horizontal projections read as shelves or beams rather than exposed strata, its front
is not visibly cut from the surrounding hill, and a mature tree occupies the structure's
terrace/face. The quarry operation remains small and peripheral on the left.

| Gate | Verdict | Exact visible evidence |
| --- | ---: | --- |
| Production evidence integrity | **PASS** | Eight matched day/night frames are present at 1280×800; the manifest is complete, lists no failures, and records grounded player support. Automatic piece counts establish node presence, not visual identity. |
| Ordinary-arrival quarry read | **FAIL** | In `01-arrival-day`, the grey structure dominates immediately, but its vertical rectangular facade, right-angle crown and long projecting bands read as a built wall/bunker. The grassy slope continues around it instead of reading as an excavated void or exposed hillside cut. `01-arrival-night` preserves only the block silhouette; excavation cues disappear. |
| Strata and benches | **FAIL** | In `01-*`, `02-*`, and `04-*`, the repeated dark strips are thin, perfectly straight cantilevers on a smooth wall. They do not read as layered rock courses or broad working benches capable of carrying people or extraction activity. The stepped slabs in front are disconnected-looking architectural stairs/platforms, not a cut-to-floor terrace system. |
| Worked floor and haul story | **FAIL** | `02-worked-floor-day` is a wider view of the same wall. Small rocks, a worker, timber edging and equipment sit at far left, but no clear loading/extraction chain connects them to the face. The broad foreground remains grassy path rather than an unmistakable worn quarry floor. At night, those props and ground planes collapse into near-black. |
| Conduit story | **FAIL** | `03-conduit-head-day` does not isolate a readable conduit head. Cyan cable and pylons cross the far-left background, visually detached from the grey face and benches. The named mechanism has no obvious grounded intake, outlet, or connection to the worked cut. `03-conduit-head-night` reduces it to a thin glowing peripheral line. |
| Grounding and scene integration | **FAIL** | Across `01-*` and `04-*`, the cut presents exposed vertical end planes and stacked slabs against untouched grass. The large tree apparently grows through or directly out of the terrace/face, reinforcing assembled geometry rather than removed earth. The structure does not form a continuous excavation basin with the surrounding terrain. |
| Night hierarchy | **FAIL** | In all four night frames the face becomes one blue-black mass, the horizontal layers lose material separation, and floor/rocks/gear merge into the foreground. The bright trainer and moon lead the eye; quarry work and conduit causality do not. |

## Three strongest gaps from the references

1. **Excavated landform versus freestanding object — `01-arrival-*`, `04-cut-face-*`.**
   The Meadows key art establishes landmarks through terrain silhouette, layered depth,
   and convincing contact with the land. R25's quarry is a smooth rectangular object in
   front of a grassy woodland, with visible end planes and a tree embedded in its mass;
   it does not read as material removed from a hillside.
2. **Readable activity chain — `02-worked-floor-*`, `03-conduit-head-*`.** Palworld's
   destination/base frames make paths, work surfaces, equipment, and the defining
   structure read together at a glance. R25 leaves its worker, rocks, haul dressing and
   cyan infrastructure as small left-edge fragments with no legible face-to-floor or
   conduit-to-operation connection.
3. **Material/value hierarchy — all night frames, especially `02-worked-floor-night`
   and `03-conduit-head-night`.** The references retain major terrain planes and
   landmark layers after dark. R25 compresses face, benches, floor and equipment into
   nearly one value; by day, the uniform grey facade and ruler-straight bands still read
   as blockout architecture rather than worked geology.

## Binding bar questions

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`? No.** The oak forest, saturated grass,
wildflowers and broad day palette belong to the Meadows family, but the named quarry
does not share the key art's integrated landform language, layered depth, or readable
night landmark hierarchy. The surrounding biome carries the match; the quarry itself
sinks it.

**B. Shown beside `docs/reference/palworld-0*.jpg`, would someone say these are trying
to be the same kind of game? No.** The colorful third-person setting points toward the
same broad genre, but the quarry's blockout-like facade, ambiguous shelf-strata, weak
worksite causality and crushed night presentation do not reach the references' authored,
shipping-quality destination read.

These gaps are scene-fixable: integrate the face into an actual excavated hillside
silhouette, replace thin shelf bands with broad irregular strata/working benches, clear
the tree/face intersection, compose the haul floor and conduit endpoints visibly against
the cut, and preserve those planes with restrained local night hierarchy. This evidence
does not establish a need for a new asset family.

R25 is **FAIL**. R19 remains the latest complete POLISH visual verdict; the later
automatic completion result is not a visual PASS.

## Review-only scope

This review adds only `REPORT.md`; it does not alter the manifest, PNGs, production art,
source, tests, configuration, or ledger.
