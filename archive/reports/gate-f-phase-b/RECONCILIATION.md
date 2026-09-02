# Gate F Phase B — Deliverable 3: historical reconciliation (§16.3) and capture rate (§16.5)

**Quarantine was broken only after `PROVISIONAL_BACKLOG.md` was hashed and
committed** (`092c229`). Hash of the frozen provisional record:

```
ff3d5e6594196b64e13e71efead885edd61f8f558ef080311c9807bee5a6b23d  PROVISIONAL_BACKLOG.md
```

Register reconciled: `ralph/reports/gate-f-historical-snapshot.md`, 208 items.
Of those, **162 are player-facing** (its Sections 1 and 1-continued) and form
§16.5's denominator. Sections 2 (36 items, not player-facing) and 3 (10 items,
superseded/obsolete candidates) are excluded from the metric per §16.5, and
listed at the end for completeness.

Every one of the 162 is classified into **exactly one** category below.

---

## §16.5 — Historical backlog capture rate

| metric | value |
|---|---|
| valid historical player-facing issues (denominator) | **162** |
| `REDISCOVERED` | **13** |
| `STILL VALID — NOT NATURALLY ENCOUNTERED` | **8** |
| `COVERED BY BROADER ROOT CAUSE` | **1** |
| `NOT REPRODUCED` | **2** |
| `MISSED BY GATE F / COVERAGE DEFECT` | **138** |
| **independent rediscovery percentage** | **8.0%** |
| **broader capture percentage** (rediscovered + root-cause coverage) | **8.6%** |

### Reading this number honestly

**8.0% is a failing capture rate, and it is not softened here.**

§16.5 warns against gaming the metric by calling difficult misses obsolete. The
opposite temptation was the live one in this run: to reclassify misses as
"STILL VALID — NOT NATURALLY ENCOUNTERED", which sounds like the run's
limitation rather than the gate's failure. That would have been dishonest.
Category 2 is for items a comprehensive run had no natural path to. **These had
a path — the Phase A protocol explicitly planned it** — and the run did not walk
it. §16.3 category 7 is exactly that case, and §16.4 says plainly what it means:
**Gate F itself failed coverage.**

Only **8** of the 162 are genuine declared §K gaps (device GPU/VRAM/thermal,
audio, first-human pacing) — protocol limitations named in advance, to be closed
by the owner's own pass. The other **138** are undeclared holes: coverage the
protocol promised and the execution did not deliver.

**§16.5's own conclusion therefore applies in full:** *"A weak capture rate
means Gate F is not yet authoritative enough. Improve the protocol before
allowing the old backlog to lose operational importance."*

**Ruling: the historical backlog remains operationally authoritative.** The Gate
F backlog does not replace it on this run's evidence. `ralph/BACKLOG.md` and the
snapshot stay live inputs until a re-run earns the replacement.

That said, the 13 rediscoveries were made **blind** — from telemetry and 79
frames, with the register unopened — and several are sharper than the historical
entry: `HIST-085`'s "boot time on the device" is now a measured 49–51 s blocking
frame reproduced 6/8 segments with the renderer off.

---

## Addendum — one classification that needs a caveat, not a change

`HIST-041` (*"the ground is a picture of grass, not grass"*) is classified
`MISSED BY GATE F / COVERAGE DEFECT` and stays there. But it needs a warning
attached, added after publication (`ADDENDUM_GRASS_FIELD.md`):

The fix that entry describes lives in `grass_field.json` as `ground_blend`,
documented there as *"the fix for the defect three blind rounds named: it mixes
the terrain's OWN colour map into the base of every blade, so growth appears to
come out of the ground instead of standing on a picture of it."* That field is
`"enabled": false` on the candidate.

So `HIST-041`'s remedy exists, is built, and **is switched off in the build under
test** — gated behind an unresolved owner decision that no container here can
settle. **Nobody may close `HIST-041` from this run's frames in either
direction:** they cannot show the fix working (it is absent) and they do not show
the defect in the system that would carry the fix. The same caution applies to
`HIST-169`, `HIST-190`, `HIST-191`, `HIST-192` and `HIST-193` — every ground-cover
item whose remedy may live in the disabled field.

---

## Classification — all 162 player-facing items


### REDISCOVERED — 13

| id | historical title | basis for this ruling |
|---|---|---|
| `HIST-004` | item icons do not encode what kind of item they are | GF-B-005 cluster. Independently found as "the hotbar does not say what it holds". |
| `HIST-017` | four different button-prompt languages in one game | GF-B-006 adjacent. Visible in frame 000312.88: M / I / R plain but [C] bracketed and greyed in the same strip. |
| `HIST-018` | the quickbar's d-pad badges read as red first-aid crosses | GF-B-005. Independently found: four white/red cross glyphs fill the controller hotbar in every X07 frame. |
| `HIST-032` | the gather route is the chapter's longest dead-travel stretch | GF-B-012, different route. One dead-travel interval of 329.8 m over 53.9 s measured on RT-05. |
| `HIST-052` | the landmark the opening points at renders as a black cutout | GF-B-008. The Rise arrival renders black (world-crop mean 15.8/255 vs 69-94 for its other frames). |
| `HIST-085` | boot time on the device, and quitting from the menu | GF-B-001. Independently found and quantified: one ~50,000 ms frame at world stand-up, 6/8 segments. Device half remains [OWNER-ONLY]. |
| `HIST-136` | the HUD takes up far too much screen | GF-B-006. The TEAM 0/5 roster block draws over the centre of the viewport; the hint bar is a permanent full-width strip. |
| `HIST-156` | unrelated items share one glyph | GF-B-005 cluster, same evidence. |
| `HIST-163` | the mill has no mill in it | GF-B-007, same systemic instance: a named landmark that does not contain the thing it is named for (quarry with no quarry). |
| `HIST-165` | the well has no well | GF-B-007, same systemic instance. |
| `HIST-174` | whole sites are still blockout, in frame | GF-B-004 + GF-B-009. Blockout in frame: a black placeholder sphere in the Hall gateway; untextured ground at relay and Hall. |
| `HIST-177` | signposts are 4.5 m telephone poles | GF-B-013. Signpost reads as a flat plank at an odd angle, text clipped at frame edge. |
| `HIST-180` | distant trees render near-black in daylight | GF-B-010. An NPC renders as a near-black unlit silhouette in full daylight at the relay. |

### NOT REPRODUCED — 2

| id | historical title | basis for this ruling |
|---|---|---|
| `HIST-072` | nothing on screen tells you what any button does | Refuted by frame. Every X07 frame carries a persistent hint bar: Map / Satchel / Call Out / Change Creature with correct per-device glyphs. |
| `HIST-167` | there are no clouds anywhere, and no cloud layer exists | Refuted by frame. 000312.88, 002431.78, 003712.84 all show a substantial cloud layer. |

### COVERED BY BROADER ROOT CAUSE — 1

| id | historical title | basis for this ruling |
|---|---|---|
| `HIST-073` | menus still do not read every input | Subsumed by GF-B-002. The X01 matrix exists to settle exactly this and could not: 303/418 cells were injected in the wrong context. The 115 valid cells were all clean. |

### STILL VALID - NOT NATURALLY ENCOUNTERED — 8

| id | historical title | basis for this ruling |
|---|---|---|
| `HIST-001` | corridor scatter density has never been measured on the target device | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |
| `HIST-042` | nobody has measured the GPU half on the device | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |
| `HIST-043` | 1.6 GB of static memory for one chapter, and nothing watches it | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |
| `HIST-044` | 909 creature bodies are built at boot and never despawned | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |
| `HIST-045` | the vegetation LOD lever is wired, gated off, and worth little | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |
| `HIST-066` | the Terrain3D vegetation LOD is written, tested, and switched off | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |
| `HIST-134` | the projected first completion is 2% over the four-hour ceiling | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |
| `HIST-204` | the game has essentially no world audio | Declared §K gap ([OWNER-ONLY]: device GPU/VRAM/thermal, audio, or first-human pacing). Not an undeclared protocol hole. |

### MISSED BY GATE F / COVERAGE DEFECT — 138

| id | historical title | basis for this ruling |
|---|---|---|
| `HIST-002` | creatures fight pressed against each other | not exercised; see the coverage-gap list. |
| `HIST-006` | lit windows do not follow the time of day | not exercised; see the coverage-gap list. |
| `HIST-007` | there is no creature bed art in the build | not exercised; see the coverage-gap list. |
| `HIST-008` | seven hero objects are still untextured blockout or absent | not exercised; see the coverage-gap list. |
| `HIST-009` | band 2's ironwood trees render blood-red | not exercised; see the coverage-gap list. |
| `HIST-010` | the second production encounter will not start | not exercised; see the coverage-gap list. |
| `HIST-013` | the combat HUD overlaps itself | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-014` | the world HUD ghosts under the dialogue panel | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-015` | text truncates mid-word with no ellipsis | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-016` | the player's body prints through menu panels | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-019` | the declared project display font is sci-fi | not exercised; see the coverage-gap list. |
| `HIST-020` | revealed map ground comes back as a featureless black strip | not exercised; see the coverage-gap list. |
| `HIST-021` | a wild creature wears the starter's body | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-022` | the combat roster degrades creatures to flat colour chips | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-023` | a hard black shadow wedge with no caster, and a black-walled pit | not exercised; see the coverage-gap list. |
| `HIST-024` | the world under the HUD is empty | §D / §E.7 - only RT-03/04/05 produced valid route data; 11 of 13 named routes unmeasured. |
| `HIST-026` | the Meadows legendary's hide colour is a presentation call the owner may want reversed | not exercised; see the coverage-gap list. |
| `HIST-027` | seven of seventeen creatures read blue | not exercised; see the coverage-gap list. |
| `HIST-028` | an alpha does not own its clearing | not exercised; see the coverage-gap list. |
| `HIST-029` | a built floor steps because of where the player was standing | §E.4 - matrix ran at 27% in-context coverage. |
| `HIST-030` | you cannot build next to a tree or an NPC | §E.4 - matrix ran at 27% in-context coverage. |
| `HIST-031` | one knocked-out creature costs the player a whole night | not exercised; see the coverage-gap list. |
| `HIST-035` | three creature beds may not be affordable near the village | not exercised; see the coverage-gap list. |
| `HIST-036` | the objective tells you what, never how | not exercised; see the coverage-gap list. |
| `HIST-038` | three merlon sizes in one castle silhouette | not exercised; see the coverage-gap list. |
| `HIST-039` | a glitch-white mesh on the band 4 ridge crest | not exercised; see the coverage-gap list. |
| `HIST-041` | the ground is a picture of grass, not grass | §D / §E.7 - only RT-03/04/05 produced valid route data; 11 of 13 named routes unmeasured. |
| `HIST-046` | Stone & Root is the chapter's quiet band | §D / §E.7 - only RT-03/04/05 produced valid route data; 11 of 13 named routes unmeasured. |
| `HIST-048` | throwing an orb still feels bad | not exercised; see the coverage-gap list. |
| `HIST-049` | your own creature eats your orbs, silently | not exercised; see the coverage-gap list. |
| `HIST-050` | landmarks an NPC told you about do not appear on the map | not exercised; see the coverage-gap list. |
| `HIST-051` | five HUD defects a blind critic named at the Ally's own resolution | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-053` | levelling up is never announced on screen | not exercised; see the coverage-gap list. |
| `HIST-054` | five more UI defects, from a second blind judge | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-055` | the tournament board reads as drawn wrong | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-056` | two of three starters face away from the camera | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-060` | one lighting rig with a dimmer and a sky swap, not four weathers | not exercised; see the coverage-gap list. |
| `HIST-062` | what a blind pass found across the whole committed frame set | not exercised; see the coverage-gap list. |
| `HIST-064` | the legendary's containment VFX renders as flat white slabs | not exercised; see the coverage-gap list. |
| `HIST-067` | what a player-built house still gets wrong up close | not exercised; see the coverage-gap list. |
| `HIST-068` | the storm road gorge still stops nothing | not exercised; see the coverage-gap list. |
| `HIST-070` | the fortress Team Tether holds has none of their apparatus on it | not exercised; see the coverage-gap list. |
| `HIST-071` | untextured white cards standing among the trees | not exercised; see the coverage-gap list. |
| `HIST-074` | reloading a save does not restore your game | not exercised; see the coverage-gap list. |
| `HIST-076` | TMs look like cards on the ground, not orbs | not exercised; see the coverage-gap list. |
| `HIST-077` | too many recipes are available at the start | not exercised; see the coverage-gap list. |
| `HIST-078` | once you pick a piece you cannot read how to place or rotate it | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-079` | the map does not show every authored trail | not exercised; see the coverage-gap list. |
| `HIST-081` | the tether pylons are not a continuous navigation line | not exercised; see the coverage-gap list. |
| `HIST-082` | day and night should be progressive and unequal | not exercised; see the coverage-gap list. |
| `HIST-083` | the torch is too dim, and held wrong | not exercised; see the coverage-gap list. |
| `HIST-084` | rocks you walk through, and invisible things you get stuck on | not exercised; see the coverage-gap list. |
| `HIST-090` | the player can still wedge on a slope beside a rock | not exercised; see the coverage-gap list. |
| `HIST-093` | blank white billboard cards in the ground or floating | not exercised; see the coverage-gap list. |
| `HIST-094` | no region has been finished to the standard the owner's stopping rule defines | not exercised; see the coverage-gap list. |
| `HIST-095` | the Meadows content umbrella | §D / §E.7 - only RT-03/04/05 produced valid route data; 11 of 13 named routes unmeasured. |
| `HIST-096` | an alpha must be more than a bigger creature | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-097` | the HUD's branded half was never built | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-099` | the three polish-phase scopes were never run as passes | not exercised; see the coverage-gap list. |
| `HIST-103` | the Warden's fallback position is 7.7 km from his own room | not exercised; see the coverage-gap list. |
| `HIST-104` | the three Sigil captains do not escalate along the route | not exercised; see the coverage-gap list. |
| `HIST-105` | the chapter's optional activities are a list, not content | §D / §E.7 - only RT-03/04/05 produced valid route data; 11 of 13 named routes unmeasured. |
| `HIST-106` | home must stay relevant after the first twenty minutes | §D / §E.7 - only RT-03/04/05 produced valid route data; 11 of 13 named routes unmeasured. |
| `HIST-107` | the visual-bar push, as scheduled work | not exercised; see the coverage-gap list. |
| `HIST-108` | three Gate E children were never separately verified | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-111` | are the villagers adults or youths? | not exercised; see the coverage-gap list. |
| `HIST-112` | Team Tether are built in a different proportion language from everyone else | not exercised; see the coverage-gap list. |
| `HIST-113` | the starter and the tank read as the same kind of animal | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-114` | four species where the owner's board paints a different animal from the mesh | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-116` | thirteen of seventeen species have no alpha treatment at all | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-117` | camps have no worn ground under them | not exercised; see the coverage-gap list. |
| `HIST-118` | flat cyan shards in the open field | not exercised; see the coverage-gap list. |
| `HIST-119` | the player-built roof needs modules this kit does not have | not exercised; see the coverage-gap list. |
| `HIST-121` | no tree in the pack reaches the key art's landmark oak | not exercised; see the coverage-gap list. |
| `HIST-122` | a dark band across the Band 3 checkpoint view | not exercised; see the coverage-gap list. |
| `HIST-125` | D5's bar question A is still "no", on the lane's own say-so | not exercised; see the coverage-gap list. |
| `HIST-126` | D4's round-4 leftovers | not exercised; see the coverage-gap list. |
| `HIST-127` | the bark retint, deliberately not changed | not exercised; see the coverage-gap list. |
| `HIST-128` | wild creatures are sited without checking the routes they block | not exercised; see the coverage-gap list. |
| `HIST-130` | the village layout does not read as a place | not exercised; see the coverage-gap list. |
| `HIST-131` | party cycling presentation was fixed in code and never looked at | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-132` | the pond-to-village route has no regression lock | §D / §E.7 - only RT-03/04/05 produced valid route data; 11 of 13 named routes unmeasured. |
| `HIST-135` | the day/night fix has never been looked at | not exercised; see the coverage-gap list. |
| `HIST-138` | there is no body in the bed at the opening wake-up | not exercised; see the coverage-gap list. |
| `HIST-140` | the map does not show all authored trails | not exercised; see the coverage-gap list. |
| `HIST-141` | does the tutorial teach the player to feed the team? | not exercised; see the coverage-gap list. |
| `HIST-144` | no visual domain has converged | not exercised; see the coverage-gap list. |
| `HIST-145` | the village road gate has no authored flanking | not exercised; see the coverage-gap list. |
| `HIST-075` | you lose camera control during a creature fight | not exercised; see the coverage-gap list. |
| `HIST-080` | the player has no idea which way to go | not exercised; see the coverage-gap list. |
| `HIST-146` | the camera watches the fight from behind your own creature's rear | not exercised; see the coverage-gap list. |
| `HIST-147` | the danger telegraph is drawn where the player cannot see it | not exercised; see the coverage-gap list. |
| `HIST-148` | a ranged move produces nothing visible in the world | not exercised; see the coverage-gap list. |
| `HIST-149` | the impact burst reads as a flat decal | not exercised; see the coverage-gap list. |
| `HIST-150` | a fight carries the previous fight's toast and target plate | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-151` | a hard-edged band across the hillside that follows nothing | not exercised; see the coverage-gap list. |
| `HIST-152` | the HUD says no creature is out while the player is piloting one | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-153` | the exploration HUD draws over every station panel | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-154` | the hotbar is not drawn during a fight | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |
| `HIST-155` | the title, the portraits and the picker are three more art languages | not exercised; see the coverage-gap list. |
| `HIST-157` | the berry bush has no berries | not exercised; see the coverage-gap list. |
| `HIST-158` | the two most-gathered plant nodes share one identity | not exercised; see the coverage-gap list. |
| `HIST-159` | the friendliest gathering verb points at a burnt tree | not exercised; see the coverage-gap list. |
| `HIST-160` | the common stone wears the exotic look | not exercised; see the coverage-gap list. |
| `HIST-161` | no tool is gripped | not exercised; see the coverage-gap list. |
| `HIST-162` | held tools are two to three times too large, and cannot be scaled from data | not exercised; see the coverage-gap list. |
| `HIST-164` | three named landmarks are two kits used twice | not exercised; see the coverage-gap list. |
| `HIST-166` | bridges and gates are overlapped fence panels | not exercised; see the coverage-gap list. |
| `HIST-168` | three water bodies read as three unrelated colours | not exercised; see the coverage-gap list. |
| `HIST-169` | half of every grass blade renders black | not exercised; see the coverage-gap list. |
| `HIST-170` | golden hour reads as mud | not exercised; see the coverage-gap list. |
| `HIST-171` | night has no moon, no horizon, and a character lit by a different rig | not exercised; see the coverage-gap list. |
| `HIST-172` | the fires emit no light | not exercised; see the coverage-gap list. |
| `HIST-173` | the ground does not respond to anything standing on it | not exercised; see the coverage-gap list. |
| `HIST-175` | the player renders standing on an NPC's head | not exercised; see the coverage-gap list. |
| `HIST-176` | the trail is ten trainer-heights wide | not exercised; see the coverage-gap list. |
| `HIST-178` | a text label floats in mid-air with nothing behind it | not exercised; see the coverage-gap list. |
| `HIST-179` | photo-real gravel on faceted low-poly rock, beside toon trees | not exercised; see the coverage-gap list. |
| `HIST-181` | stark white unshaded terrain around the gate pylon | not exercised; see the coverage-gap list. |
| `HIST-182` | eleven of twelve day frames carry the same three hue families | not exercised; see the coverage-gap list. |
| `HIST-183` | the relay camp is props at even spacing | not exercised; see the coverage-gap list. |
| `HIST-184` | faces do not survive meeting distance | not exercised; see the coverage-gap list. |
| `HIST-185` | the villager male has orange streaks on one sock | not exercised; see the coverage-gap list. |
| `HIST-186` | the Warden's cape lining renders as a translucent membrane | not exercised; see the coverage-gap list. |
| `HIST-187` | the three named captains are one person three times | not exercised; see the coverage-gap list. |
| `HIST-188` | the roster is two art packs wearing one logo | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-189` | the same species renders at two sizes in one scene | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-190` | the ground rebuild's last round has never been rendered | not exercised; see the coverage-gap list. |
| `HIST-191` | per-band ground identity is specified and not implemented | not exercised; see the coverage-gap list. |
| `HIST-192` | `forest_floor` is generated, wired and unplaced | not exercised; see the coverage-gap list. |
| `HIST-193` | the 2 m control-map cell is visible on long diagonals | not exercised; see the coverage-gap list. |
| `HIST-194` | the oaks are the wrong colour in three ways | not exercised; see the coverage-gap list. |
| `HIST-200` | partnered traversal abilities: an owner decision nothing tracks | not exercised; see the coverage-gap list. |
| `HIST-201` | the sixth-creature release has a direction and no lasting meaning | §E.2 / X03 catch lab never ran; party never exceeded 1; zero level_up, zero bond movement. |
| `HIST-202` | no rule stops a captain fight being the same fight in a different room | not exercised; see the coverage-gap list. |
| `HIST-203` | four owner decisions the plan says are still required | not exercised; see the coverage-gap list. |
| `HIST-205` | the macro-world redesign has no queue entry of its own | not exercised; see the coverage-gap list. |
| `HIST-208` | picking something up says nothing | UI surface never photographed. GF-B-003: 9,231 planned frames captured 0, and no shots/ directory exists. |

---

## Excluded from the metric (§16.5)


**Section 2 — not player-facing (36 items).** Tooling, CI, doc hygiene and bookkeeping. Excluded because §16.5's denominator is player-facing issues. Not retired: they remain in the register.


**Section 3 — superseded / obsolete candidates (10 items).** Excluded per §16.5's own instruction. Each is listed below with its snapshot title; none was moved here by this reconciliation — the snapshot had already flagged them, and this pass found no evidence to revive any.


| id | title |
|---|---|
| `HIST-061` | two suns in the sky at golden hour |
| `HIST-092` | the scatter only dresses a 512 m square at the origin |
| `HIST-101` | the relay console can be shut down without beating its captain |
| `HIST-102` | Band 4 has no harvest nodes of its own |
| `HIST-109` | lanes edit a fixture that exists to be frozen |
| `HIST-115` | there is no small creature tier |
| `HIST-120` | three creature reads need geometry the hard rule forbids |
| `HIST-129` | the Old Mill Crossing is impassable |
| `HIST-209` | the stronghold's art is standing 7,708 metres from the stronghold |
| `HIST-210` | "nothing populates the open corridor" |
