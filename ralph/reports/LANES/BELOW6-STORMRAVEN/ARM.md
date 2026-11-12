# BELOW6-STORMRAVEN: lit eyes and stronger lightning lines (F41#13, 5.97)

**Flag:** `data/config/creature_coat_flags.json flags.below6_stormraven_eye_lines` (OFF; overlay turns it on). Test: `test_creature_coat_flags` (6 tests pass with the new entry and texture).
**Texture:** `creature_stormraven_owner1101_glow_read_r2.png`, made by `make_glow_r2.py` in this folder from the remake's own glow map (source sha256 595db0cb…11f24). Import sidecar committed; `texture_import_policy.py --check` passes. No generation, 0 Meshy credits.

**Why:** G-rescore-stale-d puts the row at 5.97 and says the whole drop is Stormraven: "a flat cobalt shape with no visible face, eye or charge contrast". Owner rule (1 Nov): one elemental trait, glowing eyes plus glowing lines in its element.

**What the arm does:** same albedo (the value-lifted one that ships), species, silhouette and colours.
- The two eyes, which the old glow map drew only as thin rings, are filled lit discs 1.7 times the eye's size.
- The lightning feather lines are widened by 3 px at the map's 2048 px so they hold at creature distance.
- Emission energy 2.6 -> 3.4, and a cool rim (0.9, tint 0.35) so the head separates from the dark ground.

**CPU look** (`_sheet_cpu_idle_base_left_arm_right.jpg`, the row's idle frame, zoomed): the eye is a clear pale-blue disc instead of a small pale spot, and the chest and wing flecks are bolder. The body is still deep blue. CPU has no bloom, so how the eye glows on the GPU is unverified. No CPU judge batch.

**Seen in the frame, not from this arm:** the trainer stands on Rodkeeper Hesk's head next to the raven on both sides; the creature capture stand overlaps Hesk's post.
