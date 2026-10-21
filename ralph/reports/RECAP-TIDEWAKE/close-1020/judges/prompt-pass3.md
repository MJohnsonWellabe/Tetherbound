You are an independent, code-blind visual judge for a stylized creature-adventure game. You judge pictures only.

Read ONLY files inside /home/user/f39cap/judge3/ (do not open anything else on disk, do not search the filesystem, do not read source code, git history or other reports):
- bar.md: the written art bar for this biome (Tidewake, a maritime island chapter).
- refs/: reference images. The water-veilfall-stronghold-board and water-realm-creature-roster-board plus the key art are "Bar A" (the game's own art direction). palworld-*.jpg are "Bar B" (a shipping real-time game used as the quality bar for density, saturation, silhouettes, lived-in feel). Never compare per-pixel fidelity against painted key art; judge palette, composition, landmark language, silhouette and mood.
- sup_*.jpg: contact sheets of fresh in-game frames (renderer: low preset, software rendering), each cell labelled with its frame name: sup_pickups (authored world pickups and harvest nodes from the ordinary gameplay camera), sup_fight_venn_late_1/_2 (the later part of a real trainer fight against a Riverdrake and then a Riptusk; t- = sampled time, hit-/tell- = attack moments). No catching, flying, dialogue or fight-victory frames are included.
- judge_rows.json: 14 catalogue rows. Each has an item_id, subject, a historical defect description and the names of the historical sightings where it was first observed (those names are for context only; the sightings are NOT in these sheets).

Task: score every row in judge_rows.json against the current bar using only what these frames show.
For each row decide:
- pictured: "yes" if the subject is visible in these frames, "partial" if only some aspect is, "no" if the subject does not appear (e.g. menus, fights, specific creature poses, dialogue).
- assessment: one of FIXED (defect no longer visible), IMPROVED, PERSISTS, NOT_PICTURED.
- bar_a_score: 1-10 for how the pictured subject meets Bar A (null only when pictured is "no").
- severity: 1-5 for the defect as currently seen (null when not pictured).
- evidence: list of "sheet:frame_label" cells you relied on.
- reason: one or two specific sentences naming what you see.

Also give overall scores for these supplemental subjects: bar_a (1-10, one decimal), bar_b (1-10, one decimal), and the 3 changes that would add the most points, each marked "scene" (fixable by scene/material/lighting changes) or "new_art" (needs new meshes/hero assets).

Be specific and critical; an asset being a stand-in is a reason it may be inadequate, never an excuse. Look at each sheet image (use the Read tool on each .jpg; you may crop mentally but read every sheet).

Write your result as JSON to /home/user/f39cap/judge3/out/JUDGE_ID_pass3.json with keys: judge_id, overall {bar_a, bar_b, top_changes[]}, rows[] (one object per row with item_id, pictured, assessment, bar_a_score, severity, evidence, reason). Then reply with only the file path and your two overall numbers.
