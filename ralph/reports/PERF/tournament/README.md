# P2 tournament frame costs

Coordinator task: #525 comment 6012177191. Baseline: origin/main
8e7c11ceb5854f063c5241d62618c382803562c9. Source brief: origin/tb/perf,
ralph/reports/PERF/HANDOFF.md item 6 and Known traps; reference 10cdde31.

## Candidate, acceptance OPEN

- Telegraph glow retains its radius/alpha pulse and fresh dynamic ground/water
  heights. One synchronous rebuild resolves origin and query capabilities once
  and memoizes identical XZ samples. Unchanged draws skip only when neither a
  ground nor water API can change the result. The existing triangle strip has
  almost all distinct points at positive radius: the collapsed-point regression
  is a correctness witness, not evidence of ordinary combat speedup.
- Companion camp scans query authored candidate and explicit opt-in groups,
  retaining suffix configuration, ancestor/UI exclusions and fresh membership.
  Detached fixtures and custom unregistered suffixes retain the original walk.
  The three existing camp source scripts register themselves without changing
  their construction, persistence or resting behavior.
- Vegetation refresh uses Terrain3D's modified/missing-cell update instead of
  destroying and rebuilding all cells. Initial construction remains unchanged;
  transforms, colors, hide/restore tokens and durable harvesting are unchanged.
  Installed addon version is 1.0.2. Its [official API contract](https://terrain3d.readthedocs.io/en/stable/api/class_terrain3dinstancer.html)
  distinguishes modified/missing-cell refresh from a full destructive rebuild.

All native checks and old-code regression demonstrations remain **UNRUN**.
No before/after profiler self-time rows or visual verdict exist yet. The first
independent source review rejected across-draw reuse of dynamic terrain/water;
the candidate now resamples those queries on every rebuild. Final review pending.

Required existing checks: telegraph_glow, companion_presence and
fight_ring_occluders focused tests; demonstrate the new performance regressions
on original product code; existing smoke_net_shared_boss --tournament host
profiles under -d --profiling in quiet serialized windows. The env-gated peer
profiling patch is temporary and must never be committed. Quote callee self-time
rows, accounting for Godot's call() double counting; no FPS/device claim.

No new harness, fixture, pilot, capture tool, measurement script, network code,
test-budget change, PR or production flag change. Source-only candidate; no
criterion closure. Failed and incomplete future native logs stay preserved.
