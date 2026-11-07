STATUS: land
BRANCH: tb/item-f38-17 (carries F38#17 and F41#8 together: tb/item-f41-8 merged in, coordinator 7 Nov)
HEAD: (this commit; merged origin/main 6f8d0d79 just before writing)

# ITEM F41#8: named character silhouettes (LANE-KIT)

## Scores
- qj F41-8-12e5730a78f0-11072254 (CPU llvmpipe, three code-blind judges, 3 anchors, r 0.83, RMSE 0.646):
  base 5.47 -> candidate **5.83** (+0.36). Raw 4.8 4.6 4.2 / 5.2 4.9 4.5. Defects PRESENT -> PARTIAL, PRESENT.
- One round. Not at 7.5; the remaining gap needs distinct bodies, which a recolour cannot supply (see next idea).

## Flags (ON, judged gain)
- data/config/character_appearance_variants.json: `lanekit_f41_8_bryn` (blue-grey coat, hue 212) and
  `lanekit_f41_8_maud` (violet coat, hue 265), `enabled: true` with `_why_on` naming the round and 5.47 -> 5.83.
- data/config/stormwood_npcs.json: warden_elect_bryn and elder_maud bound with `appearance_variant_id`.
- Same installed local_historian mesh, rig, face and hair; only the olive coat cloth recoloured. No red or oxblood. No Meshy.

## Tests
- test_character_appearance_variants.gd 11/11 (combined with F38#17: record count staged + 10).
- test_dialogue_portraits.gd 13/13, test_stormwood_glass_for_bryn.gd 13/13, test_character_body_flags.gd 3/3.
- JSON parse: character_appearance_variants.json, stormwood_npcs.json.

## Files
- assets/characters/local_historian/lanekit_f41_8_{bryn,maud}_albedo.png (+ .import)
- assets/ui/portraits/lanekit_f41_8_{bryn,maud}.png (+ .import): old_perrin plate recoloured by the same script
  (tools/_capture_portraits.gd --author-appearance is gated to the six Tidewake ids).
- ralph/reports/LANES/ITEM-F41-8/recolor_coat.py (provenance: HSV recolour, hue band 45-120, s >= 0.06, v 0.08-0.85).
- data/config/character_appearance_variants.json, data/config/stormwood_npcs.json, tests/test_character_appearance_variants.gd
- ralph/reports/LANES/LANE-KIT/qj/F41-8-12e5730a78f0-11072254/ (verdict, sheet, mapped.json)

## Flags left OFF
- none for this row.

## Judges' asks
- The three roles still share one body and silhouette (a soft, chibi-leaning base). They ask for distinct bodies,
  headwear and held props per role (new_art).

## Next idea
- Per-role silhouette accessory from installed prop/outfit families (a hood or brimmed hat for Bryn, a staff or
  satchel for Maud) attached to the head/hand bone through the variant record. That is a reskin or recombination,
  so it stays within the no-Meshy rule. Expected gain is above 0.5 only if the silhouette changes at 30%.
