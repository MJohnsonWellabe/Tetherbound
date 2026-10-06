# Fresh code-blind night review — round 3

**DOES NOT PASS on visual readability.** Every named destination is identifiable somewhere in the sequence, but Bram's approach loses the playable view to building geometry and the arrival view substantially hides the player. Controller traversal was assessed separately from this pixel-only verdict.

Fresh reviewer: `night_readability_judge_round3`, spawned without inherited conversation. It received only the criterion, PNG paths, repository visual-judge rubric and reference-art access; no source, logs, previous verdict or change narrative. It inspected arrival and adjacent approach frames.

| Target | Readability | Identifiable arrival | Frames | Visual defect |
|---|---|---|---|---|
| Grandpa | Readable | Yes | 002–003 | Player obscures Grandpa in 002; 003 separates face/body and displays Talk to Grandpa. |
| Tam | Readable | Yes | 011–013 | Some overlap in 013; pale face, clothing and Greet Tam remain recognizable. |
| Mira | Readable | Yes | 022–024 | Bright interior washes out pale surfaces; face and upper body remain clear above the counter. |
| Old key | Readable | Yes | 033–036 | Yellow silhouette, localized glow and prompt are clear before pickup; disappearance is visible afterward. |
| Road gate / The Rise | Readable | Yes | 039–040 | Upper crossbeam nearly black; sign/posts/barrier distinguishable, then gate visibly open. |
| Practice Meadow camp | Readable with obstruction | Yes | 043–046 | Fire/tent establish camp; foreground boar hides player feet and HUD overlaps the right camp area. |
| Bram | **Fails approach; impaired arrival** | Yes | 058–060 | 058: structural surfaces cover center/lower screen, hiding player and navigable floor. 060: partition hides almost the entire player; Bram's head/upper torso and prompt visible. 059 is clearest. |
| Nessa | Readable | Yes | 064–066 | Pale face/yellow dress separate from ground; grass reduces foot contrast without losing figure/prompt. |
| Maren | Readable | Yes | 067–069 | Olive clothing blends with grass and player overlap affects 068; 069 separates both figures and prompt. |
| Oskar | Readable | Yes | 072–074 | Pale face/shirt stand out against doorway/ground; no blocking arrival defect. |
| Trail gate / South Bridge | Readable | Yes | 083–085 | Dark upper beam; sign/posts/open passage/fence unmistakable. |
| Pond gate / The Pond | Readable | Yes | 099–101 | Dark upper structure; white sign, warm path lighting and silhouette establish arrival. |

Criterion-relevant remaining defects: inn camera obstruction in 058 and player concealment in 060. Camp foreground crowding is lesser; destination still reads. Outdoor night lighting generally preserves paths, nearby people, gates and terrain separation.

Separate reference-art findings: muddy creature/character finish; broad isolated grass rather than organized cover transitions; cyan quest beam and angular yellow fire dominate the camp. Reference A: yes, this is the key art's world. Reference B: yes, the same broad kind of game, with lower art finish and environmental composition. These answers do not change the narrow F01#3 failure.

Product source `354c64ac69`; engine walk PASS, 101 captures, visited=12. PNGs remain local in this directory and are not committed. This failed visual verdict is preserved; it is not superseded by the mechanical PASS.
