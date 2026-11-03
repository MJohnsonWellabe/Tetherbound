# sky-storm route lane — RESULT (stopped 31 Oct 2026 by owner usage stop)

Scope: Cloudreach, Stormwood, homecoming. Branch `tb/routes-sky-storm`.

## Handoff
### State
- **Criteria closed: 0.**
- **Seam proven, 1:** Cloudreach 04 → 05. `05_stronghold` loaded the committed `cloudreach_04_high_roost` save (byte-identical copy) and passed in 2266 s at d7a12a2e (L31→L32).
  - Save and receipt: `tests/fixtures/earned_saves/sk_cr05/`.
  - Seam: `seams/cr04__cr05.json`, MATCH. Its one receipt-diff field is the legacy 04 receipt's shape; 04's save holds cap40/[1,2,3], equal to the loaded values.
  - This replaces the generated `cloudreach_05_generated_veyra_boundary` for the 04→05 seam.
- **Not run:** Cloudreach 06 from `sk_cr05`. It started at 22:47Z and was killed at the owner's stop after a few minutes, leaving no receipt or save. That makes the 05→06 seam OPEN.
- **Homecoming fix a3f79780:** already proven natively.
  - The passing `f49_s5b_home_key` (3775f93b) and `f49_s5b_home_credits` (76aefce6) pieces run source containing `PortalArrival.holds_training_row` (checked with `git show <sha>:scripts/net/foundation_portal_arrival.gd`).
  - Their input lineage is generated (`stormwood_rootgate_crown`), so the seam into them still needs a cross-cut manifest. No rerun is needed.

### Scope narrowed (coordinator relay of owner, 31 Oct)
"Do not reprove anything already proven": earned pieces whose input changes get a reviewed cross-cut manifest, not a rerun. So this lane did not rerun Cloudreach 01–04, 06→07 or Stormwood 01–07. A trained-arrival profile (e0f8908b) was added and then reverted (d7a12a2e) for the same reason.

### Open candidates (next lane, in order)
1. **Cloudreach 06 from `sk_cr05`:** `cr:06_veyra_relay`, then seam `cr05__cr06`. The earlier 06 took 1411 s at L40; this one meets Veyra at L32.
2. **Aster on real 06 output:** `06k_return_cliffhold → 06l_return_aerie → 06m_aster_duel_only → training_t4_home → training_t4_storage → training_t4_return → 06l_return_aerie → 06p_aster_chest` (the shape the `f49_c4_*` run proved).
   - Neither the duel nor the chest requires prior Master wins (`breakthrough.gd prepare_win/prepare_chest`).
   - The real 06 output is already L40/cap40/XP0, so no Altar step is needed. (The Altar does require t1–t3 wins.)
   - The chest needs room: 20 of 24 Satchel slots are used and the t4 chest adds about 8 stacks, hence the storage trip.
3. **Aster Kitchen/feed: BLOCKED on upstream training, not on this lane.**
   - Kitchen tier 2 costs `sluice_metal` 8+4 and `reef_stone` 8+2, which come only from Tidewake or Ione's chest. No earned lineage contains a T1–T3 loop.
   - Kitchen tier 1 on the real lineage is the ~4.7 h ironwood gather that the owner's no-long-runs rule forbids. It needs splitting per gather trip, or a boundary.
   - Until Meadows/Tidewake training lands in-lineage, the Kitchen/feed part stays on the generated `f49_c4_*` chain, joined by a cross-cut manifest.
4. **Cross-cut manifests:** drafts are in `crosscut_draft/`, built by `crosscut.py` (save-tree diff: party, caps, tiers, wins, recipes, flags, inventory, buildings, position, plus sha256 of every save file). Every field is still marked UNEXPLAINED and none is reviewed yet. Seams:
   - `cloudreach_06 → cloudreach_t4_aster_generated`: L40 vs L39. The generator adds t1–t3 wins/recipes, candy and the Tidewake bill, and lacks 7 earned flags.
   - `f49_c4_07 → cloudreach_07_stormward_handoff`: the input of Stormwood 01. Trained cap50/[1–4]/t4 vs untrained cap40, plus Aster chest supplies and Kitchen buildings.
   - `stormwood_05_rootgate → f49_s3_gen`: L40/cap40 vs generated L49/cap50/[1–4] with t1–t4.
     - No evidence covers L40→L49. That gap needs Altar t5 payments on a trained save: OPEN, not explainable by play.
   - `f49_s3_return → f49_s5b_gen` (homecoming lineage): trained cap60/[1–5]/t5 vs generated rootgate_crown L50/cap50. The position and Crown/Rootgate flags differ, because the generated dynamo start is placed at the Crown.
   - `tidewake_09 (old L44 lineage) → cloudreach_arrival_generated`: L44–45 vs L31. The Tidewake side belongs to tb/routes-f49.
   - Each needs per-field reasons and an independent reviewer before it counts. A level gap with no play between the two saves cannot be "explained"; it stays OPEN.

### What worked
- `chain.sh` with `RB=/home/user/rb`, run in a clean checkout.
- Evidence committed from a separate `--depth 1 --filter=blob:none` sparse clone, `/home/user/edit` (5.7 MB), so the run checkout's HEAD never moves mid-piece.

### Harness pitfalls hit (for TECHNICAL §8.1)
- `git sparse-checkout` run in the wrong directory (a failed `cd`) deleted most of the run checkout mid-import. The import then rewrote `.import` files with a non-VRAM format. Fix: `git sparse-checkout disable`, `git checkout -- assets/`, reimport. Always use `git -C <abs path>`.
- `pkill -f chain.sh` killed the calling shell (exit 144), as §8.1 warns. Kill by PID.

### Runbook (this lane)
- Setup: Godot 4.7 at `/usr/local/bin/godot`; `godot --headless --path . --import`, run twice (~50 min total on a fresh container).
- Piece: `RB=/home/user/rb PIECE_TIMEOUT=7200 tools/earned_saves/routes_kit/chain.sh <from dir> cr:<segment>:<name> ...`
- Seam: `seam_receipts.py <from> <to> <out>`. Where receipt shapes differ, read the save itself with `crosscut.py`.
