# The Old Quarry R8 — independent named-location verdict

**Verdict: POLISH — valid evidence, but not promoted to PASS.**

I inspected all eight 1280×800 PNGs at native resolution and reconciled them
against `manifest.json`. R8 fixes R7's evidence failure: the package is complete,
contains all four matched day/night views, and reports no capture failures. Every
frame records `player_on_floor: true`; ground error stays between 0.00005 m and
0.039 m, including 0.004 m at arrival. The worked-floor player is correctly
supported at y=0.256 rather than being judged against the lower Terrain3D sample
at y=-0.5. R8 is therefore usable production evidence rather than an invalid run.

## Named-location gates

| Gate | Verdict | Native-frame evidence |
| --- | ---: | --- |
| Complete production package | **PASS** | 8/8 planned frames are present at the declared resolution, `complete` is true, and `failures` is empty. The disclosure retains the production Meadows scene, terrain, scatter, quarry art, player, props, gatherables, and live encounters without production-art or progression mutation. |
| Arrival safety and grounding | **PASS** | Arrival is unobstructed and judgeable in `01`; the quarry-floor route remains open in `02` and `03`. All recorded stands are on-floor with at most 0.039 m support error. R7's missing/invalid arrival pair and false worked-floor terrain comparison do not recur. |
| Built approach and local dressing | **PASS** | The dirt approach reaches low retaining walls, a worked pad, sign, crate, barrel, sack, spoil stones, dead growth, and a three-pylon cyan conduit. `02` and `03` read as one deliberately dressed work area rather than an empty coordinate. |
| Worked-quarry identity | **POLISH / not PASS** | Equipment and spoil establish a worksite, but the extraction landform still does not read as a convincing quarry. In `01` and especially `04`, the advertised cut face is three separate pale rounded boulders sitting in grass. They do not join into exposed strata, a vertical cut, or stepped benches, and the broad arrival gives most of its area to ordinary meadow and forest while the worked floor is cropped at frame right. This reproduces R5B's core identity defect rather than closing it. |
| Route and composition coherence | **POLISH** | `03` clearly connects the floor, retaining walls, apparatus, and uphill road. The isolated face in `04` is composed apart from nearly all of that work grammar, so the viewer is not shown stone being cut from a face and moving through the floor as one spatial process. The lone straight grey slab in `03` also ends abruptly in dirt. |
| Day/night readability | **PASS for judgeability; POLISH for hierarchy** | All subjects remain inspectable at night: cyan pylons and trainer separate strongly, the warm floor pocket survives in `01`, and the pale face remains visible in `04`. However the apparatus becomes the dominant night landmark while the dark floor, spoil, and retaining route lose separation; lighting does not turn the detached boulder row into a quarry face. |

## Delta and closure

R8 should replace R7 as the valid receipt and retain the existing worked-floor,
conduit, route clearance, grounding, and night visibility. It should not replace
the ledger's POLISH grade with PASS. A passing revision needs one integrated,
laterally continuous excavated face with readable strata or stepped cuts, visibly
connected to the dressed floor and haul route from ordinary arrival distance. That
is structural integration, not another loose prop or brighter cyan source.

## Review-only scope

This review adds only `REPORT.md`. It does not alter the manifest, PNGs,
production/config/source/test/capture files, terrain/scatter, or staging state.
