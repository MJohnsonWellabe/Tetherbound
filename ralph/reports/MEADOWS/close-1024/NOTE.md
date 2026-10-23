# MEADOWS close-1024 (tb/meadows)

Rows: F17#6, F04#6, F38#0/#1/#2/#3/#5. Renderer: CPU Mesa llvmpipe, Low/Compatibility, 1920x1080. A mapped Bar A of 6.7 counts as CPU-provisional; no GPU pass is running.

## TO COORDINATOR

(send_message to the coordinator was refused with elevated_session_untrusted_device, so lines go here.)

- 2026-10-24 MESHY (F04#6 aftermath heroes, day-1 list). The judges' standing ask is that Riverwatch and Ridge share one fallen-banner/glowing-stone template and that Field's camp is "wiped rather than collapsed". The 22 Oct toll boom and brazier read worse ("a log on a post", "muddier silhouette"), so these use bigger, clearer silhouettes. Scale is against the 1.80 m trainer. Oxblood only on small Team Tether plates. Style: chunky, readable stylised realism. All stay flag-OFF until judged.
  1. MESHY: docs/art/reference/13_Tether_Energy_Pylon.png + docs/reference/palworld-02-open-field-path.jpg | 3.6 m wide x 3.2 m deep x 3.4 m tall (1.9 trainers) | Riverwatch: a wrecked Team Tether river checkpoint hut. A timber guard shack with a collapsed half-roof sliding off one side, a split door hanging from one hinge, dark iron Tether plates and a bent cyan-lensed lamp bracket. Crates are spilled at its foot, and a snapped barrier rail sits on a stone footing.
  2. MESHY: docs/art/reference/13_Tether_Energy_Pylon.png + docs/reference/palworld-03-field-boss-meadow.jpg | lying 6.5 m long x 1.8 m wide x 1.6 m tall; the standing stump is 2.2 m | Ridge: a felled Team Tether signal pylon. An iron lattice mast snapped at the base and lying across the turf, with its cracked cyan crystal head dark, torn cable coils, and the sheared stump bolted to a fieldstone plinth.
  3. MESHY: docs/reference/owner-board-2026-08-23-camp-set.png + docs/reference/palworld-05-base-building.jpg | 4.2 m long x 3.0 m wide x 1.6 m tall (collapsed; 2.6 m standing) | Field: a collapsed Team Tether field tent. A grey-teal canvas A-frame caved in on one broken ridge pole, with slack guy ropes, a scorched corner, an overturned supply chest and a toppled cookpot tripod.
  - Other Meadows rows reuse existing OFF Meshy assets first: the burrow shell, the horizon hero_model, the stronghold gate, the Hall great-hall set and the catch-kit orb. More requests follow only after a judged round names new_art. A GLB on any branch path is fine.

## Work log

- F17#6 r9: capturing the shipping baseline (main, r8 ON) on `F17-6.json`. Candidate: `F17-6-r9-apply.py`, which moves the posts to x=+-5.0 and stretches the ties to span 10 m (the archive r9 left the ties at 6.6 m, so they would have stopped short), turns hall_dressing ON without its plaster runners, and turns hall_great_hall ON.
