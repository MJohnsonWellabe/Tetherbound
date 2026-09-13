# The Rise identity R3 open-crown review (2026-09-12)

## Verdict

**POLISH — retain the bounded open-crown improvement, but do not promote The
Rise to PASS.** The wind-shaped hero tree now survives as the upper-ridge focus
in every submitted bearing, and the former close-view boulder/tree wall no
longer hides it. The set still does not make the authored climb or road-end
arrival legible enough to connect that crown to normal route play, while the
day/night value response remains too inconsistent for a finished landmark.

## Evidence integrity and disclosure

- `manifest.json` is internally complete: `complete` is `true`, `failures` is
  empty, and all eight listed 1280x720 PNGs are present as four day/night pairs.
- The four stated player stands and hero distances are coherent: 54.64 m on the
  road approach, 29.09 m at both close crown views, and 40.97 m at the west foot.
- The disclosure identifies the production Meadows scene, ordinary trainer,
  live Terrain3D, authoritative scatter/props/encounters, both authored roads,
  frozen player locomotion and clocks, hidden HUD/submersion overlay, and no
  injected scene content or progression. Inspection of the capture source
  agrees: it instantiates `res://scenes/world/meadows_playground.tscn`, waits for
  the production shell build, moves and freezes the production player, and adds
  only an evidence camera.
- The harness has no collision/occlusion `CaptureCheck`; camera height is sampled
  from live terrain rather than mechanically certified outside every solid.
  Native-resolution inspection shows no frame inside terrain, a prop, or foliage,
  so this is a proof-strength caveat rather than an invalidation of these pixels.

## Native-frame review

- `01-road-approach-day`: the crown silhouette and central hero trunk are
  detectable at 54.64 m, but cloud shadow makes almost the entire landform read
  near-night-dark. The road is only a thin, cropped strip along the bottom edge;
  the frame does not establish a route climbing to the crown.
- `01-road-approach-night`: this is the clearest full-landform view. Cool fill
  separates the rocky rise, the pale hero tree, and the lower ordinary-tree belt.
  It confirms the open crown, but the road remains bottom-cropped and visually
  disconnected from the destination.
- `02-road-end-crown-day/night`: removal/relocation of the former foreground
  competition works. The wind-shaped tree is clean against sky and the three
  restrained crown stones do not overwhelm it. A large ordinary canopy still
  occupies the right quarter, and the broad smooth foreground mound hides the
  road-end/trail relationship.
- `03-region-standing-matched-day/night`: these are valid but nearly duplicate
  the same 29.09 m stand and composition as view 02. The slightly wider framing
  confirms that the hero remains visible; it does not supply the missing route,
  arrival, sign, or crown-to-trail connection needed for a second independent
  close proof.
- `04-west-foot-profile-day/night`: the strongest R3 improvement. The steep
  landform profile, high pale hero, secondary red-trunk tree, and lower tree belt
  form a distinct hierarchy at 40.97 m. A faint diagonal ground seam suggests a
  traverse, but it does not read confidently as an authored trail, especially at
  night. The very bright moon and foliage/rock value shifts also keep the night
  presentation visibly harsher than the daytime treatment.

## Acceptance boundary

R3 resolves the prior narrow obstruction blocker: the upper hero crown is no
longer lost behind the close boulder/tree wall, and the change should be retained.
It does **not** yet resolve the ledger's requested readable crown/**trail** pair.
A PASS needs an ordinary gameplay approach and road-end composition in which the
route visibly leads into the crown, plus a repeatable daylight frame and calmer
night material values. The Rise therefore remains **POLISH**, not FAIL, because
the named rocky landform and its single wind-shaped crown tree are now consistently
recognizable and no submitted frame is visually invalid.

## Review-only scope

This review adds only `REPORT.md`. It does not modify the manifest, PNG evidence,
production/config/source/test/capture files, generated scatter, or staging state.
