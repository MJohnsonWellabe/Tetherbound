# Area 7 — HUD / UI — blind critique, round 1

Frames: `shots/census/07-ui/` — `hud_full.png` (1280×720, from
`tools/capture_exploration_hud.gd`) plus `ui_explore_prompt.png`,
`ui_inventory.png` and `ui_inventory_selected.png` (1920×1080, the three states
`tools/capture_ui_suite.gd` produced before it was stopped as too slow).

`hud_full.png` **does** carry this week's HUD changes — health bar at the
lower-left, the `Day 1 · 00:00` tracker top-centre, the shrunk MAIN STORY card
at the right — so this round judges the current state, not stale memory. What
is still unjudged: the map tab, the creatures tab, the tournament board, the
build menu, the placement ghost and the catch states.

The critic was told the rubric's own rule that **UI design is not to be
compared against the Palworld screenshots** (those bear on the world behind the
UI only), and that this is a controller-first handheld title.

Note also `04-combat-round1.md`, which judged the same HUD in combat from a
different rig and independently found the keyboard-glyph problem, the
undifferentiated hostile/ally bar colour, and the oversized boss nameplate.

Verbatim below.

---

I have read the rubric, both reference sets, the contact sheet, all four frames at full size, and zoomed crops of every interface element. Here is the critique.

---

# Visual critique — `shots/census/07-ui/`

Four frames: `hud_full.png` (1280×720), `ui_explore_prompt.png` (1920×1080), `ui_inventory.png` (1920×1080), `ui_inventory_selected.png` (1920×1080). Note up front that the HUD frame is captured at a different resolution from the other three and the layout **re-flows** between them, which I treat as a finding rather than a capture accident (criterion 6, item 6.2).

---

## 6. Interface — the heaviest criterion this round

I judged this on its own terms, not against Palworld. The question I asked of every frame is: *at handheld size, in one look, can a player read their own state and know what button does what?* The answer is no, and the reasons are specific.

### 6.1 The two vitals are the least legible things on screen

**`hud_full.png` — the FOOD bar is effectively invisible.** Crop the region x 10–210, y 300–355: the panel is drawn at roughly 15% opacity, the word "FOOD" is ochre text sitting on an ochre bar fill, and behind all of it a wooden fence rail and individual grass blades read straight through the panel. The label and the fill are within a few values of each other. There is also an unlabelled small square badge with a "B" glyph pinned to the panel's top-left corner, clipped by the panel edge, that nothing else on screen explains.

**`ui_explore_prompt.png` — the same bar, worse.** Here it is orphaned at mid-left (x 18–305, y 455–540) with nothing above it. Zoomed, the panel is 290×85px but the bar occupies only the bottom quarter — three-quarters of the panel is empty, sized for content that is not there (presumably the team roster, which has vanished from this frame). The word "FOOD" collides with the bar's left rounded cap: the D overlaps the bar geometry. "100%" is set inside the bar in white-grey on gold; "FOOD" is set outside the bar in gold on green. One readout, two type treatments, both low contrast.

**Downscaled to 35% (`hud_full.png`), the FOOD bar disappears from the frame entirely.** I cannot find it. On a 7-inch screen the player has no satiety readout at all.

**The health bar fails the same test.** `hud_full.png`, bottom-left: "100 / 100" is light grey set on the mid-green bar fill, and the bar's track is barely darker than the fill, so the bar reads as one solid green lozenge with a ghost of a number on it. There is no "HP" or heart label beyond a 14px heart icon whose green matches the bar. At 35% it is a green smear with no number.

**And the two vitals are in different places.** Health is at the extreme bottom-left; food is 350px above it in `hud_full.png` and 500px above it in `ui_explore_prompt.png`. The two numbers a player checks together are never in the same glance.

### 6.2 Safe area is violated on every edge, and the layout is resolution-dependent, not anchored

Measured margins:

| Element | Frame | Margin | % of frame |
|---|---|---|---|
| Health bar, left edge | `ui_explore_prompt.png` | 14px | 0.7% |
| Health bar, bottom edge | `ui_explore_prompt.png` | 22px | 2.0% |
| FOOD panel, left edge | `ui_explore_prompt.png` | 18px | 0.9% |
| Minimap, right edge | `hud_full.png` | 35px | 2.7% |
| Footer legend baseline | `ui_inventory.png` | ~24px | 2.2% |

Nothing sits inside a 5% title-safe box, and several elements are inside 1%. On a handheld with rounded display corners and a bezel, the health bar's left cap and the footer legend are the first things to be clipped.

Separately: between `hud_full.png` (720p) and `ui_explore_prompt.png` (1080p) the HUD does not merely scale — it **reorganises**. The TEAM 3/5 roster panel is present in one and entirely absent in the other. The FOOD bar moves from beneath the roster to a free-floating mid-left position. The quickbar grows from ~370px wide to ~555px. That is a layout responding to resolution by re-flowing rather than by anchoring, and it means neither frame can be trusted as *the* HUD.

### 6.3 The interact prompt the frame is named for is not in the frame

`ui_explore_prompt.png` shows the trainer standing beside what is clearly the intended resource node — a bare dark sapling directly at his right hand — and there is **no prompt anywhere near it**. No "Gather", no button glyph, no highlight on the node, no outline. The only world prompt in the whole set is "Call out Biscuit" in `hud_full.png`, and that one is gone here. Whatever a player is meant to learn from standing next to a harvestable, this frame teaches nothing.

### 6.4 Input glyphs contradict themselves three ways, and the controller half is the illegible half

This is a controller-first handheld title. The build speaks three different input languages simultaneously:

- **`hud_full.png` / `ui_explore_prompt.png` HUD** — keycap boxes only: `M` Map, `I` Satchel, `R` Call Out, `C` Change Creature, and `R` Call out Biscuit. **No gamepad glyph appears anywhere on the exploration HUD.** None of M/I/R/C exists on a controller. The quickbar slot badges are keycaps `1`–`5`; a gamepad has no number row. At 35% these keycaps are white specks — the player reads the four *words* and learns nothing about how to trigger any of them.
- **`ui_inventory.png` footer** — plain text pairs: "A / Enter Select", "B / Esc Close", "LB / Q Prev tab", "RB / Tab Next tab". Correct and legible, but a fourth typographic idiom.
- **`ui_inventory.png` tooltip** — pictorial glyphs: "▣ Pick up / move this stack" (a mouse-click icon with **no controller equivalent at all**), "G / ⬭ Drop", "H / ◉ Split the stack". Zoomed 4×, the two gamepad glyphs are a white lozenge containing ~5px of unreadable micro-text and a small circle with an "R" and a nub. Neither resolves into an Xbox face button or a shoulder button at any size.
- **`ui_inventory_selected.png` tooltip** — adds a *fifth*: "J / [L3] Put on the quick bar", where the controller button is bracketed ASCII text.

Worse, two of these contradict each other on the same screen. The quickbar panel in `ui_inventory_selected.png` says *"Pick a stack up with ▣, then press a slot"* while the tooltip 250px to its right says *"J / [L3] Put on the quick bar"*. Two different documented procedures for one action, visible at once.

### 6.5 Panel overlap: three UI layers fight for the same pixels behind a modal screen

`ui_inventory.png` and `ui_inventory_selected.png` both show it, and the top-right corner is the worst of it. Zoomed on x 1600–1920, y 40–420:

- The exploration **minimap is drawn on top of the Satchel panel** — its hard-edged dark square and cyan rounded ring sit over the panel border, and the panel's own "Day 1" label is printed *inside* the minimap ring, with the minimap's player triangle showing through behind the text.
- The **"Settings" tab label is partially covered** by the minimap's translucent body.
- Below it, the MAIN STORY quest card bleeds through the panel edge: "MAIN STORY", "Y", "r", "own and hear" and "dpa out" are all separately legible in the same 300px column.

The modal does not dim or suppress the HUD. It just gets drawn over most of it, and loses to the minimap.

The footer compounds this: in both inventory frames the legend row sits **outside and below** the Satchel panel's bottom edge (panel bottom ≈ y 1035, legend baseline ≈ y 1056), floating on the world, and it overlaps the still-live HUD health bar — the green bar and a ghost of "100 / 100" are visible immediately left of "A / Enter Select". Two independent UI layers occupying the same pixels with no z-relationship.

### 6.6 There is no shared panel style — five opacities, three corner radii

Counted across `hud_full.png` alone: team rows (near-opaque slate, tight radius, cyan active border) / FOOD (≈15% translucent, large radius, no border) / health (≈40% translucent, large radius, thin light border) / minimap (near-opaque near-black, **hard square corners** containing an inset cyan **rounded** ring) / MAIN STORY card (≈70%, large radius, no border) / quickbar and action bar (≈75%, medium radius, thin border). The Satchel panel adds a sixth at ≈92%.

Nothing here reads as one system. The minimap in particular is the darkest object in the entire build — darker than any world pixel — which gives the heaviest visual weight on screen to the widget carrying the least information.

### 6.7 The minimap carries no map

`hud_full.png`, zoomed: the interior is empty. No terrain, no path, no water, no fence lines, no landmark, no settlement — the tree, the barn and the boulders 30m away in the same frame are absent from it. What is present: four cyan dots at symmetric corner positions (decorative, since they cannot all be POIs), four grey edge ticks with **no N/E/S/W letters** so the player cannot determine north, a player marker drawn as a two-tone white-over-cyan triangle that reads as a mountain or a fir tree rather than a heading arrow, and a **second white triangle at the bottom that is cut in half by the ring** — an off-screen marker clipped by its own frame, which reads as a bug.

### 6.8 Iconography is five icons in four unrelated styles, and one is unidentifiable

`ui_inventory.png`, satchel row, zoomed 3×:

- Wood — three orange **outlined rings**, line-art idiom.
- Stone(?) — a pale-**pink** faceted hexagon with black seams. It reads as a peeled fruit or a rose quartz; nothing about it says stone, and its hue is closer to the berry icon beside it than to any mineral.
- Berries — flat red-pink blob cluster with dots.
- Flask — flat cream circle with a stopper.
- Axe — a pale **blue** diamond on a thin stem. It reads as a tuning fork, an umbrella or a lollipop. `ui_inventory_selected.png` confirms it is the Axe and shows the same shape at 90px in the preview pane, where it still does not read as an axe. It is also the only cool-coloured icon in the row, which at a glance signals "different rarity" when it only means "different artist".

No shared stroke weight, no shared light direction, no shared palette family.

**Stack counts sit on the cell border.** "24", "10", "6", "3" straddle the bottom outline of their cells with no background chip — "24" pushes into the selected cell's cyan border. At 35% they are unreadable smudges. A light-coloured icon behind one would erase it entirely.

**Two undocumented state markers, and they are mutually exclusive.** In `ui_inventory.png` slot 1 (Wood) carries a cyan selection outline while slot 5 (Axe) carries a green underline bar. In `ui_inventory_selected.png` the Axe takes the cyan outline and **the green underline vanishes**. So the selection state destroys the other state: you cannot see whether the item you have selected is quickbar-assigned. Neither marker is legended anywhere, and at 35% the green bar reads as a durability meter under the item.

### 6.9 Bottom-of-screen alignment is off by single-digit pixels in three places

`ui_explore_prompt.png`: the quickbar's right edge is at x≈1863, the action bar's right edge at x≈1855, the MAIN STORY card's at x≈1862, the minimap's at x≈1878. Four right-anchored elements, four different right edges spanning 23px. The action bar's centre (x≈1391) is neither screen-centre (960) nor aligned to anything. In `hud_full.png` the world prompt "Call out Biscuit" is centred at x≈660 while the action bar directly below it is centred at x≈930 — two centred-looking things centred on different axes, 270px apart.

### 6.10 Smaller interface defects, each actionable

- **`hud_full.png`, `ui_explore_prompt.png`:** the clock reads **"Day 1 · 00:00"** — midnight — over a bright midday sky with a long low sun shadow. Whatever the cause, the HUD is stating something the frame contradicts.
- **`hud_full.png`:** team rows 4 and 5 ("OPEN SLOT") are drawn at ~25% opacity with almost no panel behind them; grass and a fence read through the text. An empty roster slot is information the player needs — it is the five-creature limit made visible — and it is the second-least legible thing on the HUD after FOOD.
- **`hud_full.png`:** the KO chip on Ripplet's row is jammed between "Lv 1" and the health bar with ~2px clearance on both sides. It is also the most saturated red on the HUD, a bright coral rather than the reserved oxblood — acceptable as a danger colour, but it does not match the danger red the key art reserves for Team Tether banners, so the build now has two "danger reds".
- **`hud_full.png`:** the quickbar's "x12" count is drawn *below* the slot-1 cell rather than inside it, so slot 1 stacks three vertically separated elements — icon at top, keycap badge in the middle, count hanging outside the bottom. Cell dividers are near-invisible, so slots 2–5 read as one long empty box.
- **`ui_explore_prompt.png`:** "Change Creature" is disabled, but the only signal is ~40% opacity, and its keycap chip changes from white to pale blue-grey — a colour change that reads as a rendering inconsistency, not a state.
- **`ui_inventory.png`:** the header says "Day 1" with no time; the HUD says "Day 1 · 00:00". Same data, two formats.
- **`ui_inventory.png` / `_selected.png`:** the centre preview pane is ~480×650px and holds one 90px icon and one word. It is the widest column in the layout and ~93% empty, while the satchel grid is squeezed into six columns and the tab row is justified edge-to-edge with irregular gaps (Satchel→Creatures is visibly tighter than Build→Save). Space allocation does not follow content.
- **`ui_inventory_selected.png`:** "40/40 durability" is plain text. The one place in the build where a bar would communicate faster than a number has no bar, while the two places that have bars (HP, FOOD) are the two that are illegible.

### 6.11 What the interface gets right — stated so the fixes don't destroy it

The Satchel screen has real hierarchy: title / tab row / count / three-column body / footer, with a clear active-tab treatment (diamond bullet plus cyan underline) and body copy at a comfortable measure. At 35% the panel structure, the tab labels, the item blobs and most of the tooltip prose survive. The tooltip writing is genuinely good — "the first thing you gather and the last thing you stop needing" does more for the world than any HUD element in this set. On the HUD, the MAIN STORY card is the one element that passes the glance test cleanly. Those are the parts worth preserving.

---

## 1. Silhouette and readability at small size

At 35%, `hud_full.png`: the trainer holds up — a compact dark-brown-and-teal figure against light green, readable as a person. The boulders read as rocks. The lone tree reads as a tree. That much works.

What fails: the grass, the bushes and the flowers merge into one uniform green field with no shape variation, so nothing in the middle distance is identifiable as anything. In `ui_explore_prompt.png` the two nearest boulders (x≈1290–1440) and the dark rock behind them collapse into one grey mass because they share a value. And the creature at the bottom-left of `ui_explore_prompt.png` — the tan-and-olive form at x 400–700, y 800–1080 — is unreadable at *any* size: it is cropped by the frame edge, viewed from almost directly above, and I cannot tell head from tail, let alone species.

## 2. Colour and value structure

All four frames read as one place, which is a pass. But the value range is badly compressed: in `ui_explore_prompt.png` essentially the entire frame sits between mid-green and pale yellow-green. The darkest world pixels are the black face of the broken boulder and the dead sapling; everything else is one tonal band. **The darkest and lightest things in the frame are both UI** — the minimap panel and the white body text. A world where the interface owns both ends of the value range has no value structure of its own.

Against the key art: the board is a saturated emerald and yellow-green under a deep blue sky with warm dirt paths and strong sun-to-shade separation. These frames are yellower, flatter and lower in chroma, with a desaturated grey-blue sky and brownish cloud streaks.

On the reserved danger colour: I see no oxblood leak onto friendly elements. The red-brown rocks at the left of `ui_explore_prompt.png` and the red barn roof visible behind the inventory panel are rust/terracotta, not the banner red. The KO chip is the one place a saturated red is used, and it is used for danger — correct in principle, wrong in hue (see 6.10).

## 3. Intentionality

This reads as scattered, not placed.

- **`ui_explore_prompt.png`:** the rail fence runs across the entire frame in two long straight unbroken lines with perfectly even post spacing, no gate, no gap, no sag, no leaning post. It reads as a spline stamped along a path, not a fence someone built.
- **`ui_explore_prompt.png`:** the round-leaf bushes are one mesh at one scale repeated at near-even spacing across the whole meadow. Same for the white five-petal flowers. No clustering, no bare patches, no scale variety.
- **`ui_explore_prompt.png`:** the red-brown boulders at left (x≈40–130, y≈340–370) are the **same mesh** as the grey ones — the silhouettes match exactly. A recolour of an identical shape placed 30m from its twin reads as generator output.
- **`hud_full.png` / `ui_explore_prompt.png`:** the only tree species anywhere in the open field is the leafless dead twig — the same mesh used as the harvest node also appears as background scenery on the horizon at x≈1070, y≈215. The key art's Meadows is defined by oak groves; there is not one leafed tree in the open-field frame.

## 4. Lighting

Time of day does not read. The HUD says 00:00, the sky is midday, and the shadow direction implies a low sun. Pick one.

Terrain has almost no form: the rolling hills in `ui_explore_prompt.png` are lit nearly uniformly across their whole extent, so a hill and a flat read the same. There is no ambient occlusion at the base of anything — the fence posts meet the grass with no darkening, and the large boulder at x 1150–1350 casts **no contact shadow at all**, so it sits on top of the grass rather than in it. The trainer's own shadow in `hud_full.png` is the single best-grounded thing in the set, which makes the missing ones more conspicuous.

## 5. Horizon and depth

**The horizon is empty for its entire 1920px width in `ui_explore_prompt.png`.** No peak, no tower, no windmill, no standing stone, no settlement roofline. Every panel of the key art puts a silhouette landmark on the skyline, and its own art notes call for "silhouettes and landmarks visible from distance". There is nothing to walk toward.

Depth also collapses: distant hills flatten into a single pale-green band with no atmospheric perspective and no fog gradient, so the far hills sit at nearly the same value and saturation as the near meadow. Fog is not eating the world here — there just isn't any, and the world reads flat as a result. The sky is a smooth gradient with soft airbrushed grey-brown streaks that read as a painted texture on a dome rather than cloud with form.

No chunk seams or LOD pops visible in these stills.

## 7. Artefacts

- **`ui_explore_prompt.png`, the large boulder at x 1150–1350, y 150–330:** it has a hard right-angled **notch cut into its upper-left face** and a flat, pure near-black vertical wall on its left side that receives no light or bounce whatsoever. It reads as a failed boolean or a face with inverted/missing normals. This is the most obviously broken object in the set.
- **`ui_explore_prompt.png`, same pair:** the big boulder is smooth flat green-grey while the rock two metres in front of it is speckled grey noise. Two rocks side by side in different material languages.
- **`ui_explore_prompt.png`:** the harvest sapling **intersects the trainer's right arm** — geometry through geometry, on the hero of the frame.
- **`ui_explore_prompt.png`, bottom third:** the grass reads as flat alpha-cut cards with visible hard blade edges once the camera is close (clearest in the region around the bottom-left creature). At distance it holds; near the camera it breaks.
- **`ui_explore_prompt.png`, x 0–500, y 300–420:** a soft rectangular lighter patch on the terrain under the fence, reading as a splat/texture-blend seam rather than a lit form.
- **`hud_full.png`, x≈900–1100, y≈250–300:** a right-angled terraced step in the terrain with a flat top — an unsculpted heightmap edge, not a designed ledge.
- **`hud_full.png`, minimap:** the half-clipped white triangle at the ring's bottom edge (see 6.7).

## 8. Scale agreement

I can only run this properly in one frame, and that is itself a problem for the set.

`ui_explore_prompt.png` gives a clean measurement: the trainer is 222px from hair-crown to boot-sole, so 1.80m = **123 px/m** on that ground plane. The harvest sapling standing immediately beside him measures 237px = **~1.93m**. The tooltip in `ui_inventory.png` describes Wood as "rough-cut lengths from the meadow's **oaks**", and the Axe tooltip in `ui_inventory_selected.png` says it "takes a full swing off an **oak**". The thing you actually chop is a chest-to-head-height leafless twig. That is a scale-and-identity mismatch, and it is visible in a still.

Fence rails scale plausibly (~1.0–1.1m top rail). Boulders read 1.2m to roughly 3–4m, all plausible beside a person.

**No creature is in a measurable position in any of the four frames.** The one creature present (`ui_explore_prompt.png`, bottom-left) is cropped by the frame edge and shot from near-overhead at minimum distance. So the criterion the rubric added specifically to catch relative-creature-size errors cannot be run on this set at all. If a future survey is meant to answer it, at least one creature needs to stand on the same ground plane as the trainer, fully in frame.

---

# VERDICT

## Part 1 — The three things that most separate these frames from the references

*(Per the brief, these are judged on the world, not the UI.)*

**1. The horizon is empty; the references never are.** In `ui_explore_prompt.png` the skyline runs 1920px without a single landmark. Every key-art panel plants one — a peaked mountain, a windmill and tower over the settlement, a standing stone against a sunset ridge. `palworld-04-plateau-landmark.jpg` builds its entire composition around a distant blue spire with a stone ruin as the mid-ground step toward it, so the player always has a target and a sense of how far they have come. These frames give a player nothing to walk toward, and no way to tell where they are. This is the single largest gap.

**2. The world is scattered, not placed, and it is one green value.** `ui_explore_prompt.png` gives one grass species at one height and hue, one bush mesh at one scale evenly spread, one boulder mesh recoloured, an unbroken evenly-posted fence, and no leafed tree at all. `palworld-02-open-field-path.jpg` and `palworld-03-field-boss-meadow.jpg` are the direct comparison: the same open-field problem, solved with layered ground cover at three or four heights, rock formations clustered into outcrops rather than sprinkled, real value separation between lit grass and shadowed trees, and a road that visibly goes somewhere. The key art's Meadows is defined by oak groves and clear streams — neither is present in these frames.

**3. Nothing is grounded, and there is no depth.** The large boulder in `ui_explore_prompt.png` casts no contact shadow, the fence posts meet the grass with no occlusion, and the distant hills sit at the same value and saturation as the near meadow. Both `palworld-01-boss-fight-forest.jpg` and `palworld-04-plateau-landmark.jpg` use graded atmospheric haze to push distance back and strong contact shadow to sit objects in the ground; the key art does the same with painterly ambient occlusion. Here the darkest and lightest pixels in the frame both belong to the UI, which is what "no value structure" looks like.

## Part 2 — The two bar questions

### A. Do these frames read as belonging to the world of `tetherbound-meadows-keyart.png`?

**No.**

What carries: the palette family is roughly right — yellow-greens, warm dirt path, wooden rail fences, a blue-grey sky — and the trainer's proportions and colourway would not look out of place in the DAY panel. Nothing on screen actively contradicts the board's colour identity, and the danger red has not leaked onto friendly elements.

What sinks it: the board's Meadows is *characterised* by four things and these frames have none of them. Oak groves — there is not one leafed tree in `ui_explore_prompt.png`, only a dead twig used as both harvestable and scenery. Streams and ponds — absent. Settlements — absent from the open-field frames (a barn roof is glimpsed only behind the inventory panel). Landmarks visible from distance — the horizon is empty. The board's own note reads "cozy and inviting, but with hints of mystery"; an empty flat field with two broken-looking boulders and a dead sapling is neither cozy nor mysterious. It is unfinished.

### B. Would someone shown these beside `palworld-0*.jpg` say they are trying to be the same kind of game?

**Yes, but only just, and only on the strength of the character and the ground cover.**

What carries it: the third-person over-shoulder camera framing, the stylised-realist trainer with plausible proportions and readable clothing shapes, genuinely dense grass rather than a texture with props stabbed into it, a party roster in the top-left, and a creature companion following the player. Those five things together do read as the same genre. The Satchel screen's density and tooltip writing also read as a survival-crafting game of that family.

What holds it back to "just": in `palworld-02-open-field-path.jpg` and `palworld-03-field-boss-meadow.jpg` the frame is *full* — multiple creatures with nameplates, a visible objective, terrain with silhouette, layered vegetation, a fight reading as an event. `ui_explore_prompt.png` has one human, one half-cropped unreadable creature, and roughly 70% of the frame given to undifferentiated grass. The single creature in frame carries no nameplate, no health bar and no team indicator, so a player looking at it cannot tell which of Biscuit / Ripplet / Kite it is or whether it is the one the roster says is KO'd.

### The split: fixable by changing the scene vs. needs art that is not in the build

**Fixable by changing the scene, the layout, or the config — this is the work:**

- Every interface defect in section 6 except 6.8. Safe-area margins, panel opacity and contrast on FOOD and HP, co-locating the two vitals, one panel style with one radius and one opacity ramp, suppressing or dimming the HUD behind the Satchel modal, moving the footer legend inside the panel, fixing the four mismatched right edges, giving the minimap terrain and a north marker and one player-arrow shape, and fixing the "OPEN SLOT" and stack-count legibility. None of this needs new art.
- **Unifying the input glyph language.** Choosing gamepad-primary with keyboard secondary everywhere, and killing the mouse-only "▣" hint, is a data/config job. *Redrawing* the two illegible controller glyphs is small art (see below).
- The clock/sky contradiction.
- Landmark placement, prop clustering, scale variety in the scatter, breaking the fence into runs with gates and gaps, adding value separation via a real lighting setup, adding atmospheric haze on distance, adding contact shadows / AO.
- Composing the survey frames so a creature stands fully in frame on the trainer's ground plane, and so the named "explore prompt" frame actually contains a prompt.
- Fixing the notched boulder and the terraced heightmap step — sculpting, not new assets.

**Needs art that is not in the build:**

- **Leafed trees.** There is no oak in these frames. Groves are the Meadows' defining feature in the key art and cannot be scattered into existence from what is on screen.
- **Water.** No stream, pond or shoreline exists in this set.
- **A horizon landmark silhouette** — a peak, a tower, a windmill, a standing stone. Placement is free; the object is not.
- **A second and third ground-cover species**, and a second bush and boulder form. One mesh recoloured is visible as one mesh recoloured.
- **A redrawn icon set.** Five icons in four idioms, with the Axe unreadable as an axe and stone rendered in berry-pink. This is a small, cheap art task but it is art, not layout.
- **Legible controller button glyphs.** The current lozenge and circle glyphs do not resolve at any size and need to be redrawn or replaced with a proper glyph font.
- **A settlement or any built structure in the open-field view.** The key art's cozy-inviting read comes largely from roofs, wells and banners on the skyline; none of that is available to place.
