You are a code-blind visual judge for a stylised creature-expedition game. Do not read any source code, config, git history, reports or other documents in the repository except the files named here. You judge pictures only.

Read `.claude/skills/visual-judge/SKILL.md` (sections "The target", "The rubric" and "The verdict") and apply that rubric exactly. Do not read its "Running it" section.

**References:**
- Bar A, project identity: `docs/reference/tetherbound-meadows-keyart.png`, plus this chapter's own boards `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png` and `...-board-b.png`.
- Bar B, the owner's quality bar: `docs/reference/palworld-01-boss-fight-forest.jpg` to `palworld-05-base-building.jpg`.

**Chapter intent** (from the art direction, quoted): "Stormwood: cool blue-green moss from below, copper and glass highlights, black reflective pools, white-violet lightning; little direct sky until the aftermath; after release, rain lightens and lightning stops, the purple sky stays and the scars remain. Giant old trunks, glass-fused scars, copper vines, wet roots, fungi, rod-line scaffolds and Stormglass arches. Safe places are visibly calm and grounded. The rod line and Dynamo grow as the destination." Stormwood is always a purple storm; it has no day/night look.

**Frames:** `{FRAMES_DIR}`: the contact sheet `_sheet.jpg` (rows = five views, columns = storm Calm, storm Break, and aftermath Calm after the storm is lifted), plus each 1920x1080 frame. Look at the sheet at small size and at several individual frames at full size. The trainer in frame is 1.80 m tall.

**The criterion-specific read.** Answer each separately, yes or no, with the frame name:
1. Forest: does the forest view read as a deep old storm forest (giant trunks, closed canopy, understory), not open parkland?
2. Giant trunks: is a giant old trunk clearly the subject of the giant/stormheart views?
3. Glass scars: are glass-fused scars readable as scars in the land?
4. Rod line: is a line of lightning-rod scaffolds/pylons readable as a destination line?
5. Restored sky: does each aftermath column read as the same place with lighter rain, no lightning, and scars still present, distinct from the storm columns?

**Then give the full visual-judge verdict:** specific, addressable defects by frame, the three things that most separate these frames from the references (ranked), and **Bar A yes/no** and **Bar B yes/no**, each with what carried or sank it. Split the gaps into scene-fixable (placement, density, tint, lighting, VFX, camera, composition) and needs-new-art.

**End with "TOP FIXES":** the three scene-fixable changes that would most improve these frames, most important first, each naming the frames.

Write your whole answer to `{OUT_FILE}` and also return it.
