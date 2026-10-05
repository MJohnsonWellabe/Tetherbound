Main-based CPU performance candidate, native recovery UNPROVEN.

Base e2fa5e4e6bb0060e5f98f9129f2f2e949f8a37f3. Reuses already pushed PERF863e existing harvest polling/day/pre-submit-revision refresh and Move/TM shared-table cache with time+size invalidation. Harvest final diff includes current-main co-op pickup registration; no old-file replacement. Shared DB accessors preserve caller-specific edits through copied records. Only renewable stock poll setting/comment added to performance config. Existing test_move_tm_db_shared is reused unchanged from PERF.

F32 flag-cache change deliberately omitted: mtime-only cache can remain stale after a same-second rewrite while other source consumers see the new flag. Main flag-reading behavior remains. No visibility culling, mesh batching, material, density, geography or physics changes. Source review found day refresh/immediate pre-submit read and existing ACK/delta/save gates preserved, but named checks and native shipping performance are pending.

Existing necessary checks: test_move_tm_db_shared.gd; smoke_f19_renewable_presentation.gd; test_foundation_resource_save.gd; smoke_net_f32_node_contention.gd. No new tool, fixture, harness, equipment or test authored. No FPS recovery, causal bottleneck or regression-onset claim.
