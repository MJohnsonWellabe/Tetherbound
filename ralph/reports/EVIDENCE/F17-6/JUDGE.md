# F17#6 code-blind verdicts (coordinator)

The judge sees only the frames and the bar or failure list, never code.

| Time (CT) | Round | Source | Verdict |
|---|---|---|---|
| 4:42 AM Mon 12 Oct | r2 | ev-coop-chapters 555beaa81 | Exterior PASS; interiors FAIL: sealed arches flat by day and black voids at night, locked door a loose slab before a blue surface, floating debug labels, no day/night change, raw shrine cut, "The Rise" banner inside the Hall, bench and companion on the door path |
| 7:45 AM Mon 12 Oct | r3 | ev-coop-chapters 01644bfff (code ff6ddc413) | Street day and night PASS. Fixed: locked door, shrine framing, bench/door path. Still FAIL: night nave far-end black void (~1.5/255); sealed infills flat with a square patch decal and brighter at night than by day; labels still UI text (clipped "Sea…", illegible plaques, the HUD panel hides the Cloudreach sign); the shrine room doesn't change at night; open portals indistinguishable from sealed. r4 must self-measure luminance and self-judge before sending. |
| 1:24 PM Mon 12 Oct | claude r1 ship candidate (landmarks-claude 48b6e75f) | ship-candidate-Low.jpg | WEAK: night pools and arch reveals better; new defect: the pale stone surround pokes past the timber posts and shows as corner brackets. One fix requested. |
| 1:34 PM Mon 12 Oct | claude r1 ship candidate fix (landmarks-claude beda40db) | ship-candidate-Low.jpg | PASS: soft lantern-placed night pools in both night views; real recessed reveals in all four views with the surround inside the timber; 0 new defects. hall_interiors_claude_enabled ON at the next merge (signage sub-flag parked OFF). Criterion stays open for the full 8-frame interior set. |
