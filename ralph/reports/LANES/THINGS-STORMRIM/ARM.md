# THINGS-STORMRIM: the white bloom on the player and the pale officers in Stormwood dialogue

**Rows.** F41#15 (6.97) and the other Stormwood dialogue rows (F41#7, #11, #20). Judges, 3/3: "the player's head blooms white at the left edge"; Nysa "reads as a pale ghost"; a white rim glow on Marrow's hair.

**Cause.** Not the conversation lights (identical with them off or at 0.4). Stormwood runs the character night rim at full weight (`player_character_rim_scale` 1.0 in `stormwood_look.json` and the surge base) under ambient 1.65 and exposure 1.35. The rim was made for dark nights; here it adds a lit edge to skin that is already near clip, and High's glow turns it into a halo. The same weight drives the uniform rim on the Stormwood officers.

**Change.** Config only: the rim weight goes to 0 in Stormwood (clear and surge). No code. The keys sit in LANE-PLACES' look files but only drive character materials; nothing in the world changes.

**CPU** (`_sheet_rim_on_vs_off_cpu.jpg`, Nysa's post; top main, bottom arm): clipped pixels on the player's head 20.1% -> 0.7%; the player's hair returns to brown and the face shows features; Nysa's face goes from white to skin tone. Scenery is identical.

**Risk.** The rim was also the officers' rank separation (F41#18). If the judges miss it, the next step is a low weight (0.25) rather than 1.0.

**Expected.** +0.5 or more on the Stormwood dialogue rows (named 3/3 on every frame).

**Ask.** Whole Stormwood dialogue set, base and arm, High. It can share one capture session with THINGS-STORMRULE (same frames).
