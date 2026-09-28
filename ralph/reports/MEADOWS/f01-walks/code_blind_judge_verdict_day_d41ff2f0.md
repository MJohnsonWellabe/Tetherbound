# Code-blind judge verdict: `ralph/reports/MEADOWS/f01-walks/day_d41ff2f0/`

Criterion: "Normal-controller DAY walk reaches every opening NPC, camp and gate". I judged readability and function only. Inputs were the 29 JPG frames in the directory and `run_village_walk_lines.txt`. I did not read any source, config, tests or other reports.

| Target | Frame(s) | Reached? | Evidence in the image |
|---|---|---|---|
| Grandpa | 002, 003 | YES | 002 is indoors. The player's back hides almost all of Grandpa, and only white hair shows past the trainer's head. In 003 the camera has moved and Grandpa is fully visible beside the trainer: white hair and beard, green scarf and vest. The prompt reads "Talk to Grandpa". |
| Bram | 013, 014 | YES | He is inside the inn. A blond man stands behind a bar with bottle shelves and a "ROOMS - ALE - STOCK" sign. His lower half is behind the trainer's head, but his face is visible. The prompt reads "Greet Bram". In 014 a large hanging lantern takes up the foreground on the left but does not cover Bram. |
| Tam | 021, 022 | YES | In 021 Tam is hidden behind the trainer in a stone-house doorway, and only grey hair shows. In 022 Tam is fully visible beside the trainer: grey-haired child, green vest and shorts. The prompt reads "Greet Tam". |
| Mira | 026, 027 | YES | The two frames are identical. Mira stands behind a plain counter in a small timber room: auburn hair, green hooded top. She is in clear view above the trainer's shoulder. The prompt reads "Greet Mira". |
| Oskar | 033, 034 | YES | In 033 Oskar is mostly behind the trainer. In 034 he stands clear beside the trainer by a fence and tree: dark hair, white shirt, brown vest. The prompt reads "Greet Oskar". |
| Halda | 041, 042 | YES | In 041 Halda is behind the trainer, with a blue-grey head showing. In 042 she is fully visible to the right of the trainer: blue-grey hair, white top, green vest. The prompt reads "Greet Halda". A second villager stands in the background, but the prompt makes the target unambiguous. |
| The old key | 049, 050, 051 | YES | In 049 the key reads clearly as a key: a large gold key (round bow and shaft) hangs on a wooden post right of the Rise gate, with a soft glow. The prompt reads "Take the old key". In 050 the view is from the side, and the key is smaller but still gold and glowing on the post. In 051 the post is empty and the prompt has gone back to "Call out Bud", so the key was taken. In 055 Grandpa says "There you go. The old key still turns." |
| RoadGate "The Rise" | 053, 054, 055 | YES | A heavy timber arch with a round crest and a hanging "The Rise" sign. A "The Rise" signpost stands on the left. In 053 and 054 the gate is closed: a wooden gate leaf with an X-brace fills the opening, and the prompt reads "Try the gate". In 055 the leaf has swung open and Grandpa's dialogue box confirms the key worked. |
| Practice Meadow camp | 056-061 | YES | 056: a tent and cart are visible from the village path. 057-059: the approach is clear, with the cart, a pitched canvas tent, an orange campfire ringed with stones and a bedroll. 061: the arrival view is unobstructed. It shows the tent, a cot with a blanket and pillow (the bedding), a campfire in a stone ring, a log seat, a sack, a wicker crate and the cart against a house. It reads as a lived-in camp. |
| TrailGate | 070, 071 | YES | A timber arch like the others, with a large "South Bridge" sign and a "South Bridge" signpost on the right. The trainer stands in the opening on a dirt path, and a fence leaf is swung open on the left. The frame clearly reads as a gate. The in-world name is "South Bridge", not "Trail", but I cannot check that mapping from images. |
| PondGate | 084, 085 | YES | A timber arch with a "The Pond" sign. In 085, from a side angle, the X-braced gate leaf lies open on the left and the trainer stands under the arch. It clearly reads as a gate. |

**Overall: DAY WALK: PASS**

Every one of the 11 targets is reached, and in at least one frame each is identifiable as what it is.

## Secondary observations (these do not change the verdict)

1. **The "end" frames often hide the NPC.** In 002, 021, 033 and 041 the chase camera sits right behind the trainer, and the trainer's body covers most of the NPC. The "reached" frames that follow fix this. Still, the camera does not reframe on its own when the player stops in front of an NPC.
2. **Camp arrival (061):**
   - The camp shows no name label and no interaction prompt; the HUD shows only "Call out Bud". It reads as a camp from its props alone.
   - The trainer stands very close to the fire-ring stones, with feet on the log seat, so the figure overlaps the flame in screen space. It reads as standing at the fire's edge, not beside it.
   - The fire is a flat, two-tone orange flame shape. It reads as fire, but it is stylised compared with the rest of the scene.
3. **Wild creatures at the camp.** Two boar-like creatures (057-061) and several rabbit-like creatures graze a few metres from the fire. A blue objective beacon stands in the same area. This is clear enough, but the first camp is crowded.
4. **The walker stalled on its way to the camp.** Frames 058 and 059 are nearly identical, and the log records two sidesteps around "Trainer_1". No trainer is visible in either frame, so the blocking body is off-camera or not visible.
5. **The opening frame (001)** shows a small campfire burning against the house wall next to the front door. It is an odd placement, but not a target.
6. **The Rise signpost label (049)** is partly hidden by the trainer ("The Ris…"). Later frames show it in full.
7. **No gate prompt on the open gates.** On "South Bridge" and "The Pond" the prompt stays "Call out Bud", with no gate prompt, even at 0.1-0.2 m. That fits gates that are already open. On the RoadGate, the "Try the gate" prompt appears only while it is closed.
