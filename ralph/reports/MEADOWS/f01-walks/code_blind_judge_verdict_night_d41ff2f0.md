# Code-blind judge verdict: `ralph/reports/MEADOWS/f01-walks/night_d41ff2f0/`

Criterion: "Normal-controller NIGHT walk reaches every opening NPC, camp and gate." Each target must be reached and must be recognisable in the frame for what it is, at night. Only functional readability is judged here; art polish is out of scope.

Inputs read: every `.jpg` in the directory and `run_village_walk_lines.txt`. No source code, config, tests or other reports were read. The HUD clock reads "Day 1 · 23:00" in every frame, with a night sky and moon. The log ends `PASS route=visits time=night captures=81 max_off_road_m=0.00 visited=11`.

| Target | Frame(s) | Reached? | Evidence in the image |
|---|---|---|---|
| Grandpa | 004 | YES | Indoors, beside the player. A white-haired, bearded old man in a green vest, fully readable. Prompt reads "Talk to Grandpa". |
| Bram | 014 | YES | Behind the bar counter of a tavern interior, with bottle shelves and an "ALE · STOCK" sign. He is small in frame but clearly a person. Prompt reads "Greet Bram". |
| Tam | 022 | YES | Outdoors at night beside a stone-and-timber house and a well/shrine. A dark-haired villager faces the player and her silhouette is clear against the lit doorway. Prompt reads "Greet Tam". |
| Mira | 027 | YES | Indoors behind a counter. A brown-haired woman in a green top, fully lit and readable. Prompt reads "Greet Mira". |
| Oskar | 033 | YES | Outdoors in a fenced field at night. A dark-haired villager faces the player with a rim light, and his figure is distinct from the dark grass. Prompt reads "Greet Oskar". |
| Halda | 041 | YES | Outdoors beside a timbered house. A blue-haired villager in a green jacket is next to the player and readable. Prompt reads "Greet Halda". |
| The old key | 048, 049, 050 | YES | 048: a gold key-shaped object hangs on a dark post beside "The Rise" gate. It is lit by small glows and reads unambiguously as a key in the world, apart from the prompt. 049: at closer range the key is still visible on the post, but small, as a yellow shape at about screen centre-right. 050, after the take: the post is bare, the prompt is gone and the log says `satchel has key=true`. |
| Practice Meadow camp | 055–058 | YES | 056 (approach) is a clear camp read: a canvas tent, a wooden cart, a campfire with bright yellow flames in a stone ring, and a log or bedroll beside it. 057/058 (arrival): the tent, a dark bedroll and the cart are directly behind the player, and the campfire is at lower right. It still reads as a camp. The arrival view is partly obstructed; see secondary observations. |
| RoadGate "The Rise" | 048, 052, 053, 054 | YES | 052/053: a timber arch labelled "The Rise", with lanterns, a closed rail gate and the prompt "Try the gate". 054: the gate leaf has swung open, and Grandpa's dialogue reads "There you go. The old key still turns." The lock and unlock are both visible. |
| TrailGate | 066, 067 | YES | A timber arch labelled "South Bridge", with lanterns and an open swing-gate leaf. A "South Bridge" fingerpost stands beside it. The player stands in the gateway. The gate and its destination read clearly at night. No prompt appears (log `prompt="-"`), which is consistent with an open gate. |
| PondGate | 080, 081 | YES | A timber arch labelled "The Pond", with lanterns and an open swing-gate leaf. A "...ond" fingerpost is at the left edge. The player walks through the gateway. It reads clearly. |

**Overall: NIGHT WALK: PASS**

## Secondary observations (these do not decide the verdict)

1. **Camp arrival framing (058).** The camera faces heading ~283°, away from the fire. The quick-slot HUD panel at lower right covers most of the campfire, so only the flame tips show above the panel. The player's body blocks the middle of the tent. No world geometry blocks the view. The camp still reads from the tent, bedroll and cart, and from the flame tips. The approach frame 056 is the best camp shot; the arrival frame is weaker.
2. **No camp prompt at arrival.** The log records `prompt="-"` for the camp at 2.79 m, and 058 shows only "Call out Bud". This frame therefore shows that the camp can be reached and recognised, but not that it can be used.
3. **Wild creatures in the camp.** 056 shows a wild creature (a moss-backed quadruped) standing next to the camp tent and fire, and 057/058 show one (a boar/hog) at the right edge. A cyan beacon column also stands just beside the camp. This adds clutter but does not stop the camp reading as a camp.
4. **Grandpa's room (004).** Several furniture pieces on the right render as pure black silhouettes with no detail. This is a lighting/material problem, not a readability failure for Grandpa.
5. **Villager tint at night.** Tam, Oskar and Halda take a strong blue/violet cast, and Oskar has a magenta rim light. They remain readable as people.
6. **Key at close range (049).** Near the pickup, the key is small and partly lost against the post and nearby glow. The mid-range frame 048 carries the in-world read.
7. **Gate naming.** The internal name "TrailGate" appears in-world as "South Bridge". This is fine for players, but reviewers who map log names to signs should note it.
