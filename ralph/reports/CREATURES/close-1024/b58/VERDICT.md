# b58: grounded flinch for Aquaryn, Tidecoil and Solmane vs main (CPU, three judges)

Near-bar close-out (coordinator, 27 Oct). GPU F36#1 main-1024 had Aquaryn 7.49, Tidecoil 7.45, Solmane 7.33. The pass summary read the recipe hit as rearing up, "more a pounce than a flinch", and saw it lift off the floor.
- Candidate 26b31761: the held shove regenerated at gain 0.75 (was 1.5) with the same hold, hit role only. Gain 1.5 reproduces each live clip byte for byte.
- This is the same change that took Cloudfang (7.64) and Breezetail to MET on GPU CO8.
- The water forms of Aquaryn and Tidecoil share these profiles.

Tiles: standing, hit 025 / 050 / 075. Sheet `_sheet_b58.jpg`: main | flinch, rows Aquaryn, Tidecoil, Solmane.

Anchors: f36_0_gap:C3, f36_0_npc:C1, p2_094_r4. Fit: slope 1.44, r 0.94, RMSE 0.48, **confirming**.

| species | main (mapped) | flinch (mapped) | gain | pounce, not a flinch (main / flinch) |
|---|---|---|---|---|
| Aquaryn | 6.22 | **7.08** | **+0.86** | PRESENT x3 / FIXED, PARTIAL, FIXED |
| Tidecoil | 6.12 | **6.94** | **+0.82** | PRESENT x3 / PARTIAL, FIXED, PARTIAL |
| Solmane | 5.79 | **6.65** | **+0.86** | PRESENT x3 / PARTIAL x3 |

Call: **GPU READY** (9/9 judge-set preferences).
- Remaining reads, not from this change:
  - Solmane still rears "with the hind feet planted"; the far stage camera hides its face.
  - The serpent and dragon materials read glossy and toy-like.
  - The ruler overlaps Tidecoil's coil (stage staging).

Checks: `run_tests --only=f36_pose,creature_pose,rest_pose,water,creature_body`: 546 tests, 0 failed.
