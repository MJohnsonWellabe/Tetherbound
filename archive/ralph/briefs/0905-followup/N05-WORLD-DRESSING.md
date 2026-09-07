# N05-WORLD-DRESSING

**Source:** W08-DIALOGUE-CAMERA-0904, W06-FINALE-0904 reports.

## Why
A cluster of small, concrete world-geometry and dressing defects, all fixable with existing
installed assets (props, lighting config) — no new meshes.

## Owns
Village fence placement data (find via `grep -rn` for the fence panel/corner node names —
likely `data/config/village_boundary.json` or a scene file, not a script), the inn interior
scene/dressing data, `scripts/world/stronghold.gd` (the endgame chamber), and
`scripts/world/meadow_healing.gd` OR the courtyard NPC data (whichever actually owns the
gauntlet trainer's stand/pose — confirm before editing).

## Do

**1. Village fence geometry clips (W08).** In a frame near Halda's conversation stand, one
fence post passes through another fence run's rails at a different angle and into a boulder
behind it (approx. frame coords x 900–980, y 255–310); a second post floats clear of the
terrain with visible ground beneath it (≈ x 865, y 265–315); a rail ends in mid-air (≈ x 985,
y 275). Find the fence placement data for this specific junction and correct the positions/
rotations so posts and rails meet cleanly and every post sits on the ground.

**2. Inn interior is an undressed greybox (W08).** Bram's inn interior has no bottle, shelf,
stool, tankard, barrel, sign, or lamp, despite his own dialogue referencing "beds through the
back" and "I keep stock too." Add a modest set of these using the installed prop family
(check `assets/props/` for what already exists — tavern-appropriate props are likely already
in the tree from other interior work; do not generate anything new). This became more visible
once another lane's dialogue camera push-in puts the player's eye on this wall for the length
of a conversation.

**3. Stronghold gauntlet trainer doesn't react to the world changing (W06).** After the
garrison withdrawal sequence, the courtyard gauntlet trainer NPC stands in the exact same
spot and pose as before — it should also react/withdraw as part of the "world changed" beat.
Find where the garrison-withdrawal trigger fires and add this trainer to whatever list of
NPCs already reacts to it (if the withdrawal logic already has a manifest of reacting NPCs,
add this one to it rather than writing new trigger-handling code).

**4. Stronghold chamber lighting/contrast (W06), named by three independent blind judges.**
In `stronghold.gd`'s chamber scene: cyan light-bars read as debug draws rather than intentional
lighting (retint or remove); no contact shadow under the tether machine or the bound/freed
creature (add one via the existing shadow-casting light setup used elsewhere in the project,
not a new light type); single-key lighting crushes blacks (add or brighten a fill light);
chamber walls show overlapping slabs with a visible black gap between them (a placement/scale
fix on the wall pieces, not new geometry). Also: at distance, "you cannot tell there is a
creature there at all" — the bound/freed creature has no value separation from its surroundings;
fix via lighting/rim contrast, not asset changes.

## Verify
- Items 1–3: a smoke or manual check confirming the corrected geometry/reaction; a rendered
  frame from the same camera position the original defect was found in, to confirm visually.
- Item 4: capture the same chamber frames the three judges saw (check
  `ralph/reports/W06-FINALE-0904/REPORT.md` for the exact capture tool and stand list, likely
  `tools/_capture_stronghold_climax.gd` or similar) and run one blind-judge round focused
  specifically on these four named defects — do not re-litigate anything else about the scene.

## Acceptance
All four fixes verified against the exact defect each judge/lane named. The chamber's blind-
judge round confirms the four named defects are resolved (or, if not fully resolved, exactly
what changed and what didn't is stated honestly).
