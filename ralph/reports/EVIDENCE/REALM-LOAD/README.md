# Realm load: Meadows build profile and safe wins (co-op lane)

**Setup:** headless Godot 4.7 (as the two-peer proofs run), this host, Mon 12 Oct 2026 CT. Profiler: `tools/_profile_meadows_build.gd` (`--rebuild` builds twice in one process). Timings come from `BOOT_LOG.phase`, now one line per settlement sub-build.

**Before** (guest's in-proof crossing, about 110 s):
- Vegetation: 32–38 s (`group_by_model` 11.2 s, batches 9 s, placements 7 s, reorder 5.1 s).
- Burrow Warrens: 22–24 s (bank grid/quads 16 s; ground clearing 5 s).
- `clear_area()` across all callers: 54 calls, 25 s.
- Village NPCs: 3–8 s.
- Cold first terrain-data load: 84 s, once per process.

**Fixes, all output-identical:**
- **Cover clearance (`cbaaa1984`):** zones precomputed. `group_by_model` 11.2 → 1.7 s.
- **Warrens bank (`cbaaa1984`):** colour and route memos. Quad loop 11.6 → 4.0 s.
- **`clear_area` (`a09025510`):** harvest-key cells, the batch stream-cell index, and one deferred MMI refresh per world build. 25 → 12 s.
- **Scatter reorder (`636312dc2`):** unique sparse orders slotted. 5.1 → 1.4 s.
- **Warrens bank surfaces (`5c0b4cc53`):** cached for a same-process rebuild. Key: every input plus a 17x17 terrain-height lattice.
- **Proof of identity:** an end-of-build digest (harvest keys, harvest points, solids, collision placements, render positions) and the bank mesh/collision hashes equal the pre-change code. Profile log: `profile_rebuild_5c0b4cc53.log.gz`.
- **Tests:**
  - New: `test_catalog_cover_clearance`, `test_scatter_bake_reorder`, and 2 `clear_area` index tests in `test_vegetation_clear_area_gather_points`.
  - Related suites green: vegetation and catalog 53/0, warrens 29/0 (its 6 script errors predate this), bake 25/0.

**After:**
- Standalone: first build 75–89 s; same-process rebuild 51 s.
- Live two-peer proof, guest Meadows rebuild (`_ready` to first frame): 64 s and 67 s. Guest crossing home 86.5 s (was 136); guest arch crossing 76 s (was 125).
- F11#3 full proof passes (`f11_3_run_5c0b4cc53_plus_diag/`, exit 0).

**Target (under 60 s for the guest's live rebuild) not yet met.** Remaining:
- Vegetation about 20 s; about 6 s of it is creating 56k harvest-point nodes.
- Warrens about 10 s: native per-spot `remove_instances`, and the cap.
- Healing, NPCs, quarry and stronghold: 2–4 s each.

**Open:** one run failed at #43: the guest's arch request back to Stormwood got no reply (`f11_3_fail_43_no_reply/`). It did not recur. `session._host_portal_action` now logs every request it drops silently, to catch it if it does.
