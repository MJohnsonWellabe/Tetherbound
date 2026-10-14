# Cloudreach load under the 120 s readiness cap (host_first_realm), Systems lane

Tue 13 Oct 2026 (CT), tb/ev-systems. Pre-existing on main: crossings measured 112–127 s.

## Profile (standalone headless load of cloudreach_cliffs.tscn, --profile-realm-load)
~210 s of work: regions 2.8 s, routes 30 s, landmarks 1.4 s, cloudreach_ground_cover.build ~133 s
(9.08 M placement attempts -> 2.27 M tufts), look.dress cover pass ~33 s (turf fill 23 s:
690 k samples; per-sample route and settlement checks), everything else < 1 s.

## Fix (product, output byte-identical)
- 6b4bc098 ground cover: the XZ planting-field test (no RNG) runs before the surface-height and
  exclusion lookups; per-patch constants and exclusions are prepared once per patch.
- e693eeec look: route polylines and settlement centres are converted once.
- Proof of identity: SHA-256 over every MultiMesh buffer under ProceduralGroundCover
  (2,267,267 instances) and LookGroundCoverFinish (657,291), old vs new: identical hashes.
- Standalone build 221 s -> 144 s. No visual change, so no deferral and no readiness change.

## Proof (local, software GL)
- smoke_net_session_host_first_realm 3/3 PASS. Host/guest crossing times: 73.3/70.4,
  71.0/69.2, 72.3/65.7 s (was 112–127 s on main 122682ad; the target is <= 80 s).
- smoke_net_split_realms PASS: guest crosses into Cloudreach in 66.7 s and back in 61.5 s.
- Remaining cost (P2, option a): ground cover is still ~80 s of GDScript in a standalone build.
