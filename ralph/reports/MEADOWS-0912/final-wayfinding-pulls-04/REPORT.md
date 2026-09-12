# Independent visual verdict — `final-wayfinding-pulls-04`

**Overall: FAIL — the Long Field/off-path composition now passes, but the 532 m world beacon still does not**

`manifest.json` is complete and internally consistent: `complete: true`, 12/12
expected 1280×720 PNGs, no capture failures, one production Meadows scene load,
and the companion dismissed through the production path. I inspected every PNG at
native resolution and compared the set directly with `final-wayfinding-pulls-02`
and its FAIL report. Round 04 closes the obstructed Long Field road view and retains
the accepted south-trail creatures. The objective repair is only partial: the 66 m
pair is strong, but ordinary foreground trees still defeat the world-space beacon
at the required 532 m road stand.

## Strict owner-row verdicts

| Owner row | Verdict | Frame evidence |
|---|---|---|
| T1 #1 — next-objective world beacon | **FAIL** | `02-objective-near-destination-day/night` now gives a clear, narrow cyan column from ground through canopy and sky at 66 m. It is easy to associate with the South Bridge target and restrained enough not to dominate the road. The required 532 m pair does not do the same: in `01-objective-road-approach-day`, the target line is effectively absent behind the large foreground trunk and aligned route trees, with at most a tiny cyan sliver beside the distant post/tree. `01-*-night` exposes only that short sliver, not a usable column. The minimap's 532 m distance and the large quest card remain usable UI, but they cannot substitute for the owner's requested world beacon. |
| T1 #6 — fill the long south-trail creature gap | **PASS** | `05-trailpup-sightline-from-road-day/night` presents a pale Trailpup directly over the dirt-trail mouth at 51 m, retaining a distinct body and ear silhouette against both green day and dark night woodland. `06-bramblebun-sightline-from-road-day/night` adds the large Bramblebun group at 55 m on the next open road stretch, with the nearest face/body readable and additional pale creatures farther up the trail. The 86 m Wayfarer view also carries the taller Meadowhart group beyond its signal. Together these are repeated authored wildlife beats rather than one cluster immediately before camp. |
| T1 #7 — peripheral glow draws attention off path | **PASS** | `03-wayfarer-signal-from-road-day/night` is now a clean production-road view: the warm signal/fire and adjacent reward/chest highlight form a compact bright point between darker trunks at 86 m, surviving both presets without an obstructing foreground bush. `04-wayfarer-signal-at-detour-day/night` resolves that promise into the warm signal plus a separate cool-blue reward glow. The accents are visible but do not wash the woodland. |
| T3 #1 — authored off-path pull | **PASS** | The road pair establishes a destination off the main dirt line: warm fire/reward light, a small chest/bench silhouette, and at least one tall pale Meadowhart shape share the opening between trunks. At 15.6 m, `04-*` pays it off clearly with the signal, chest/bench, separate glowing pickup, and three large Meadowharts framed between the trees. All four elements retain useful separation at night. This is now a legible reason to leave the road, not content revealed only after walking blindly into foliage. |

## Delta from `final-wayfinding-pulls-02`

- **Resolved:** the Long Field road pair is no longer photographed through dense
  foreground leaves. The route-side warm signal, reward/site furniture, and
  Meadowhart destination now read from the actual 86 m road stand and resolve at
  the detour in day and night.
- **Retained:** both south-trail creature pairs remain clear, companion-free
  production views. Trailpup and Bramblebun continue to break up the previously
  empty run toward camp.
- **Partially resolved:** the near objective pair no longer aligns the beacon
  through a canopy and is a valid receipt at 66 m.
- **Still blocking:** the 532 m objective pair still loses the useful beacon body
  behind ordinary foreground trees. `visual_visible: true` in the manifest proves
  that its node is enabled, not that a player can see or use it.

## Smallest remaining correction and recapture

Make the beacon's distance presentation retain one clearly continuous upper segment
through ordinary trunk/canopy occlusion at the existing 532 m road stand, while
preserving the current thin, non-obnoxious 66 m treatment. Then recapture the same
532 m and 66 m day/night objective pairs. Retain the accepted Long Field site and
all creature placements unchanged; if the final acceptance package must remain a
single 12-frame receipt, rerun those eight unchanged frames alongside the repair.

This report judges visible production presentation only. It makes no claim about
objective completion, creature encounter triggering, pickup interaction, or route
collision.
