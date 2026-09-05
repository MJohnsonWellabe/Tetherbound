extends CanvasLayer

## The real exploration HUD — the owner's Palworld-inspired layout
## (`ENVIRONMENT_AND_UI_BIBLE.md` §6/§6.6). This is the M-C integration pass:
## it mounts `party_strip.gd` and `stamina_arc.gd` (built and unit-tested
## standalone, `tests/test_hud_widgets.gd`) and `minimap.gd`/`map_baker.gd`
## (owned by a concurrent pass; mounted defensively, never edited here), and
## builds the rest of the layout — the active-creature block, the player vitals
## cluster, and the objective line — directly in code with `UITokens`
## factories.
##
## STRUCTURE VS DATA. The .tscn keeps only what genuinely wants to be
## hand-authored scene state: `Root` (and its load-bearing mouse_filter,
## see the .tscn's own comment), `HotbarPanel`, `Prompt` and `DebugReadout`.
## Everything the Palworld layout adds — the creature block, the vitals cluster,
## the mounted widgets, the objective block — is built once in `_ready()` and
## polled every frame in `_process()`, the same "structure once, poll every
## frame" split `menu_tab.gd` and `party_strip.gd` already use. Every Control
## created here sets `mouse_filter = MOUSE_FILTER_IGNORE` itself, for the same
## reason the .tscn's Root does (see its comment, and `tests/smoke_mouse_look.gd`,
## extended in this pass to walk the whole subtree and enforce it).
##
## Sized for the Ally: the project authors at 1920x1080 and stretches
## canvas_items, so the pixel positions below are real handheld screen space,
## not anchors that reflow at other resolutions. That is a deliberate scope
## limit shared with the rest of this HUD, not an oversight.
##
## F3 debug overlay is untouched by this pass — still OFF -> PERF -> FULL,
## still drawn into `DebugReadout`, which the .tscn keeps as before.

## A bar/cluster at rest fades to this rather than to zero: gone-and-back-again
## on every full heal reads as a layout pop, faint-but-present does not. Blind
## visual review flagged the first value tried (0.28) as unreadable — the fill
## and track blended into each other and the low-alpha edges read as a
## rendering artefact rather than a calm bar.
const FADE_ALPHA := 0.55
const FADE_SPEED := 2.2

## The exploration HUD's own fade while a combat throw is being aimed (spec
## §10.1) — the reticle over the wild creature is the thing to look at, and this
## HUD's own bars/hotbar/minimap are not part of that decision. Distinct
## from `FADE_ALPHA` above (that one is the per-widget idle fade for a
## calm-but-present bar); this one dims the whole `Root` at once, the same
## way `combat_hud.gd` dims its own enemy plate and move grid for the same
## reason.
##
## Fully to zero, not a partial dim -- was 0.35 (DEFECT 2, blind visual
## review of `shots/ui/11-capture-reticle.png`: "the minimap and MAIN STORY
## panel are ghosted to near-zero opacity but still occupy their space --
## outlines and unreadable remnants over the mountain... this state reads as
## a rendering bug"). `combat_hud.gd::_draw_grid()` already drew the same
## conclusion for its own enemy plate, in words: "a 35%-alpha plate over open
## sky read as 'a broken grey ghost', not 'temporarily de-emphasised'" --
## true there because the enemy plate has translucent backing over open sky,
## and true here for the same reason: the minimap and objective block are
## also translucent panels over open sky/terrain, so a 0.35 multiply left
## their borders and text legible enough to read as broken, not quiet. This
## HUD's own bars/hotbar have no equivalent readable-but-shouldn't-be state
## at 0.35 (a blind critic never flagged them), but there is no reason to
## keep one corner of the fade at a value another part of this same codebase
## already proved reads as a rendering bug -- one target for the whole `Root`,
## same as before, just the target combat_hud.gd already picked for the
## identical shape of widget.
const AIM_FADE_ALPHA := 0.0
const AIM_FADE_SPEED := 4.0

const READOUT_INTERVAL := 0.1

## F3 cycles OFF -> PERF -> FULL rather than toggling.
const DEBUG_OFF := 0
const DEBUG_PERF := 1
const DEBUG_FULL := 2

## ~2 seconds of frames at 60 Hz.
const FRAME_WINDOW := 120

const MB := 1048576.0

const CREATURE_SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
## OW10: the one "who owns input right now" question both world-verb polls ask.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const PERF_CONFIG := preload("res://scripts/world/performance_config.gd")
const PERF_TRACE := preload("res://scripts/world/perf_trace.gd")
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const AUDIO_CUES := preload("res://scripts/ui/audio_cues.gd")

## EV9's owner-commissioned HUD glyphs (`docs/specs/ASSET_LEDGER.md`, staged
## `369ecc5`). `orb_capture.png` has no mount yet — there is no orb-count
## panel anywhere in this HUD to hang it on (removed somewhere between the
## first EV9 slice's own note and this file's later full rewrite; a fresh
## grep of scripts/ui confirms no orb counter exists today) — so it stays
## unwired rather than forced onto an unrelated widget.
const ICON_HP := "res://assets/ui/icons/hud/hp_heart.png"
const ICON_STAMINA := "res://assets/ui/icons/hud/stamina_bolt.png"
const ICON_CREATURES := "res://assets/ui/icons/hud/creatures_paw.png"

const PARTY_STRIP_SCRIPT := "res://scripts/ui/party_strip.gd"
## PROGRESSION-VISIBLE (prompt 73, D76): the feed the moment banner and the
## strip's xp/bond fields read, and the cue player for a Moment.
const PROGRESSION_FEED := preload("res://scripts/creatures/progression_feed.gd")
const BOND_MILESTONES_HUD := preload("res://scripts/creatures/bond_milestones.gd")
const CREATURE_PROGRESSION_HUD := preload("res://scripts/creatures/progression.gd")
const AUDIO_MANAGER_HUD := preload("res://scripts/audio/audio_manager.gd")
const GAME_MENU_HUD := preload("res://scripts/ui/game_menu.gd")
const STAMINA_ARC_SCRIPT := "res://scripts/ui/stamina_arc.gd"
## Owned by a concurrent agent this pass (see CLAUDE.md task header) — never
## edited here, only loaded and called defensively. If either file is missing
## or fails to produce a usable node, the minimap simply does not mount; every
## other block on this HUD is independent of it.
const MINIMAP_SCRIPT := "res://scripts/ui/minimap.gd"
const MAP_BAKER_SCRIPT := "res://scripts/world/map_baker.gd"

const HOTBAR_SLOTS := 5
## Action name IS the glyph id (input_glyph.gd's GLYPHS dict uses the same
## keys), so one list serves both jobs.
const HOTBAR_ACTIONS := ["hotbar_1", "hotbar_2", "hotbar_3", "hotbar_4", "hotbar_5"]
## Named constants (not the magic 28/16 this used to inline directly into the
## bbcode format string) so `smoke_hud_handheld_legibility.gd` can assert real
## physical pixel sizes against the values actually drawn, the way it already
## does for `LEGEND_GLYPH_PX`.
## HUD-SCALE: 36 -> 26 on both. The badge sat exactly on the old
## render-pixel floor (36 authored x 0.667 = 24), which is the reason this
## pair was never cut before -- and that floor was measuring the wrong thing.
## 26 is `HUD_SCALE.GLYPH_ARCMIN`, measured off a 1:1 render of the real pad
## badges rather than derived through a scale factor the device does not have.
const HOTBAR_GLYPH_PX := 26
const HOTBAR_COUNT_FONT_SIZE := 26
## GF-B-005: the item's own icon, 28 -> 64.
##
## The strip photographed as "one red B and four identical white/red cross
## marks" across five different regions, while the satchel actually held orbs,
## potions, berries and revives. Two things made that true at once. `HIST-018`
## has the first: the four crosses ARE the Kenney d-pad badges, and every d-pad
## variant in the pack (Default, Double, `_outline`, `_round`, Xbox, Gamecube)
## uses the same plus-sign-with-one-differentiated-arm, so at true render size
## the four bindings are one shape repeated. Replacing that art is
## OWNER-BLOCKED -- `CLAUDE.md` forbids spending a generation without
## owner-supplied reference art, and the register's own ruling is that no
## suitable asset exists.
##
## The second is this number, and it is not blocked: the badge was drawn at 36
## and the ITEM at 28, so the least distinguishing element in the slot was also
## the biggest. Inverting that is the half of the acceptance criteria this lane
## can actually satisfy -- "each filled slot's contents are identifiable, and
## the binding badge is secondary to the item rather than covering it."
##
## 64, not larger: the slot is 112 wide with about 104 of inner width, and the
## icon shares its column with the badge and the count below it.
##
## HUD-SCALE: 64 -> 44. GF-B-005's ordering rule is what matters here and it
## survives -- the ITEM stays clearly the largest thing in the slot (44 against
## a 26px badge and a 26px count), which is the same 1.7x lead it had at 64
## against 36. What changes is that the whole slot stops being sized as though
## it were going to be downscaled by a third. 44 authored px subtends 27.1
## arcmin, which is still half again the glyph floor.
const HOTBAR_ICON_PX := 44

## The item id that means "I am building". `data/items/items.json`'s hammer,
## which already existed as a workbench tool -- CONTROLLER-MAP gave it the
## second job rather than adding an item, because the pad map has no build
## button left and a tool in hand is how every other verb is chosen now.
const BUILD_TOOL := "hammer"

const HOTBAR_MESSAGE_SECONDS := 2.2

## Pixels of clear screen between the hotbar panel's real bottom edge and the
## top of the context prompt, and the prompt row's own resting height.
##
## The two used to be pinned to the screen bottom independently — the prompt at
## -140, the hotbar at -144 — which read as one crowded block, and the first fix
## nudged the hotbar up by a hand-measured 26px. That number described one
## arrangement of one frame: the row collided again the moment either side
## changed height, which the hotbar does every time its message row appears.
## Stating the GAP instead and deriving the prompt from it is the same look with
## the relationship written down. TUNABLE.
## OW8: the gap is now `Root/BottomDock`'s own `separation` in the scene, not a
## number this script applies to the prompt's offsets. Third report of the same
## overlap, after two passes that each tuned a static gap and were each defeated
## by the hotbar's hidden Message row joining its VBox and growing the panel
## 30px. A VBoxContainer owning both controls cannot lay them into each other at
## any height, so there is no gap left to compute here.

## Owner directive, playtest pass: "name some of the areas and uncover them
## like fortnite maps do." `map_state.gd::take_pending_region_announcement()`
## queues the newly-entered region's display name once; this is how long the
## banner stays up before fading, same read-and-clear/timeout shape as
## `_hotbar_message` above just with a longer hold -- a location card is meant
## to be noticed, not glanced at.
const REGION_BANNER_SECONDS := 3.2
## The banner's own slot, lifted out of `_build_region_banner()`'s inline
## offsets so `_build_objective_hint_card()` can place itself under the banner
## rather than at a hand-tuned y that would silently stop being under it.
const REGION_BANNER_TOP := 120.0
const REGION_BANNER_HEIGHT := 48.0

## Owner playtest 2026-08-30B, item 19: "There should be something that
## tracks what day number and time we're at." Persistent, not a toast --
## unlike the region banner above it shares this top-centre lane with, it
## never hides. Sits ABOVE `REGION_BANNER_TOP` (120) with clearance to spare
## at `DAYTIME_READOUT_HEIGHT`'s own font+leading, so a region announcement
## never overlaps it.
##
## Deliberately outside the left column and the minimap/objective column on
## the right -- item 21 is a separate, still-open complaint that those two
## already crowd the screen, and this is a NEW element, so it goes in the one
## authored-space lane nothing else occupies at rest: top-centre, above where
## the transient region banner draws.
const DAYTIME_READOUT_FONT_SIZE := UITokens.FONT_LABEL
const DAYTIME_READOUT_TOP := UITokens.HUD_INSET
const DAYTIME_READOUT_HEIGHT := 32.0

## --- layout (spec §6/§6.6, numbers inlined per the task) --------------------
## All positions are in the HUD's own 1920x1080 authoring space (top-left
## origin), matching the rest of this file's "sized for the Ally" convention.

## HUD-LAYOUT: the creature panel, the vitals cluster and the party strip
## used to be positioned with a fixed, hand-measured Y coordinate each,
## authored against a 1920x1080 canvas. That stopped being true the moment
## `_root`'s ACTUAL canvas stopped being 1080 tall -- this project stretches
## `canvas_items` with `aspect="expand"`, and the Ally's real 1280x800 window
## (aspect 1.6, narrower than the authored 1920x1080's 1.778) computes an
## effective canvas of 1920x1200, not 1920x1080. `Root/BottomDock` (the
## .tscn) already accounts for this correctly -- it anchors to the CANVAS
## BOTTOM (`anchor_top/bottom = 1`, `offset_top = -460`) so its position is
## always "460px above whatever the real bottom is." This left column never
## got the same treatment: `CREATURE_BLOCK_POS.y = 830` and
## `VITALS_POS.y = 1006` were both measured against an assumed 1080-tall
## canvas and anchored from the TOP. On the Ally's real 1200-tall canvas,
## BottomDock's top edge sits at 1200-460=740 -- squarely inside both blocks
## (830-992 and 1006-1070), a genuine, reproducible overlap confirmed by
## rendering the real HUD scene at 1280x800 and reading `get_global_rect()`
## on every block, not by eyeballing a screenshot. `_reflow_left_stack()`
## below fixes the ROOT cause: the whole left column (party strip, creature
## panel, vitals cluster) is now positioned from the CANVAS BOTTOM, using
## `_root.size.y` read at runtime, the same anchor BottomDock already uses --
## so the two can never drift apart again regardless of aspect ratio.
const CREATURE_BLOCK_X := 56.0
## Mirrors `Root/BottomDock`'s own `offset_top` in the .tscn exactly -- see
## the header above. Keep the two in sync if either changes; each file's
## comment points at the other.
## HUD-SCALE tried -340 here, on the reasoning that the dock's contents had
## lost ~120px and a dock still reserving 460 would hold the left column that
## much higher than it needs to be. **That reasoning was wrong and the
## measurement says so**, which is worth leaving in the file rather than
## quietly reverting.
##
## `Root/BottomDock` is a `VBoxContainer` with `grow_vertical = 0`, so its own
## rect is CONTENT-sized and grows upward past these offsets -- it never
## reserved 460 in the first place. Measured on the live HUD at both supported
## canvases: the quiet dock is 290 tall, which puts its real top 386 above the
## canvas bottom, i.e. already well above the 340 nominal. So -340 did not free
## any space; it moved the NOMINAL top BELOW the real one, and
## `left_stack_bottom()` placed the vitals cluster 6px inside the dock.
## `smoke_hud_handheld_legibility.gd` caught it immediately.
##
## Back to -460, which clears the quiet dock (386) and its transient message
## row (416) with margin. The left column's real constraint was never this
## constant.
const BOTTOM_DOCK_TOP_OFFSET := -460.0
## Clear space kept between the left column's lowest element and
## BottomDock's nominal top -- generous enough to survive BottomDock's own
## transient growth (the hotbar's Message row adding ~30px while a hotbar
## response is showing) without the two ever touching.
const LEFT_STACK_CLEARANCE := 40.0
## Top-edge margin for the party strip's reveal. Matches `UITokens.HUD_INSET`,
## the same top-edge margin the minimap and objective block already use, so
## the reveal lines up with the rest of this HUD's top row rather than
## picking its own.
const TOP_SAFE_INSET := UITokens.HUD_INSET
const PARTY_ACTIVE_GAP := UITokens.GAP

## The creature panel no longer carries a fixed height -- see
## `_build_creature_block()`'s header for why hand-placed offsets were the
## actual defect, not just this file's old Y math. Width keeps a floor (not a
## cap): a `PanelContainer` only grows past this if a row's real content
## (namely "READY TO CALL OUT", the longest header string) genuinely needs
## more, which is the "honest minimum size" this task asked for instead of
## fixed pixels a longer string could silently overflow.
const CREATURE_BLOCK_MIN_WIDTH := 374.0

## HUD-POPUP: the party strip used to hug the creature panel from directly
## above (`party_strip_position()`'s old header spelled out the tradeoff:
## its own `TOTAL_HEIGHT`, 540, never fit in the room actually left above a
## correctly bottom-anchored creature panel at either supported canvas
## height, so the clamp let the reveal draw its bottom rows straight over
## the panel behind it). A blind critic then confirmed exactly that frame --
## the panel's own title compositing through a party row's name, its HP
## readout floating over the row beneath it, six distinct collisions from
## one shared rect. Of the critic's three fixes (opaque the popup, move it
## off the list, or hide the list while the popup is open), this takes
## "move it off the list": the party strip now reveals in its own screen
## region, to the right of the persistent status column, rather than
## contesting the same vertical space the creature panel and vitals cluster
## already own. That is a strictly larger fix than opacity -- opacity only
## stops the TEXT from bleeding through; the rows and the panel would still
## occupy literally the same rect, which is what let Kite's KO tag and the
## incoming HP readout float ambiguously between two widgets in the first
## place. Chosen over "hide the list": OP21-12's whole point was showing the
## roster DURING a cycle, not replacing it with the single-creature panel at
## the exact moment the player most wants to see where the new active
## creature sits among all five. The strip's actual X offset is computed in
## `party_strip_position()` from the creature panel's REAL width, not a
## constant here -- see that function's own header for why a fixed guess at
## the panel's width reopened this same defect once already.

## HUD-SCALE: 300 -> 244, tracking `VITALS_VALUE_FONT` down from 38 to 26.
## The caption column, both bars and both value labels all derive their own
## x/width from this constant and `VITALS_CAPTION_WIDTH` below, so this is the
## one number the cluster's geometry needs.
const VITALS_WIDTH := 244.0
## HUD-POPUP task 3/4: the "100 / 100" HP value used to draw at
## `UITokens.FONT_LABEL` (23) -- ~10.7 physical px cap height at the Ally's
## 0.667 canvas_items scale, the exact sub-16px violation the critic named.
## `HUD_READABLE_FONT_SIZE` is the floor every other label on this HUD
## already clears; the satiety row gets the same treatment plus the icon it
## never had (task 4: "next to a heart-marked HP bar it is a mystery
## meter") -- a "FOOD" caption standing in for real icon art, since a new
## icon asset is exactly the kind of spend `CLAUDE.md`/`conventions.md`
## reserve for an owner-supplied reference sheet, which does not exist for
## this glyph.
## How far the vitals cluster's backing plate is drawn OUTSIDE the cluster's own
## rect, on every side. Named (it was an inlined 8.0) because
## `party_strip_position()` has to clear the plate, not the cluster: the strip
## rests directly above it, and a first render of GF-B-006 measured the roster's
## fifth row drawing into the plate while every rect check against the CLUSTER
## passed. What the player sees is the plate.
const VITALS_PLATE_OVERHANG := 8.0
const VITALS_BAR_HEIGHT := 20.0
const VITALS_ROW_GAP := 10.0
const VITALS_VALUE_FONT := HUD_READABLE_FONT_SIZE
## HUD-EMPHASIS: 68 -> 92. A blind critic's real render showed "FOOD" (4
## capitals at `VITALS_VALUE_FONT`, 38) running past the caption column's old
## 60px text box (`VITALS_CAPTION_WIDTH - 8`) and directly into the satiety
## bar's own fill -- "numerals half-on half-off the bar." Widened so the
## caption has real room at this font size; the satiety bar and its value
## label both derive their own x/width FROM this constant already, so
## nothing downstream needed a second fix.
## HUD-SCALE: 104 -> 76. This was widened to 104 so "FOOD" (4 capitals at the
## old 38px `VITALS_VALUE_FONT`) had room; at 26 the same four capitals need
## about 73px, so the column follows the font that set it.
const VITALS_CAPTION_WIDTH := 76.0
const VITALS_HP_ROW_Y := 28.0 + VITALS_ROW_GAP
const VITALS_SATIETY_ROW_Y := VITALS_HP_ROW_Y + 34.0 + VITALS_ROW_GAP
## Real content height of the vitals cluster (buff row 0-28, HP icon/bar/value
## row, satiety caption/bar/value row, 6px bottom pad) -- used only to size
## the gap the left stack's reflow leaves above it; the cluster's own
## children still lay out with the same local offsets they always have.
const VITALS_HEIGHT := VITALS_SATIETY_ROW_Y + 34.0 + 6.0

## HUD-BACKLOG-20 (owner playtest 2026-08-30, item 20: "Put the player's
## health bar in the lower left"). The HP icon/bar/value move out of
## `_vitals_cluster` into their own widget, built by
## `_build_player_health_bar()` and positioned by
## `player_health_bar_position()` below, anchored to the true canvas bottom
## instead of stacked above `Root/BottomDock` the way the rest of the left
## column is.
##
## OWNER-0902-HUD-TEAM-MENU (owner playtest 2026-09-02, finding #11: "food
## bar needs to go down by the health bar"). `vitals_position()` now sits
## BESIDE `player_health_bar_position()` (see that function's own header),
## both anchored near the true canvas bottom -- which means the satiety
## cluster's own row spacing now has to fit the SAME tight, fixed 96px band
## the health bar always did (`Root/BottomDock`'s own `offset_bottom` in the
## .tscn), not the roomy column above the roster it used to share. The row
## gap between the buff chips (0-20 local y) and the satiety row below them
## used to be 18px (`VITALS_HP_ROW_Y`'s old 38, left over from when this row
## sat where the HP row used to); tightened to the standard `VITALS_ROW_GAP`
## (10) to reclaim the 8px that band cannot spare. Nothing about the buff row
## or the satiety row's own content moves -- only the gap between them.
const VITALS_FOOD_ONLY_ROW_Y := 20.0 + VITALS_ROW_GAP  ## buff chip bottom (BUFF_CHIP_SIZE, 20) + the standard row gap
const VITALS_HEIGHT_WITHOUT_HP := VITALS_FOOD_ONLY_ROW_Y + 34.0 + 6.0

## The extracted HP row's own local geometry -- the same icon/bar/value
## layout `_build_vitals_cluster()` used to draw at `VITALS_HP_ROW_Y`, just
## re-anchored so the row's own top (the value label, which drew 8px above
## `VITALS_HP_ROW_Y`) starts at local y 0 instead.
const HEALTH_BAR_ROW_Y := 8.0
const HEALTH_BAR_CONTENT_HEIGHT := 34.0
## Clearance kept between the satiety plate's own backing plate and the true
## canvas bottom edge -- satiety is the LOWER of the two stacked plates (owner
## playtest 2026-09-03, item 8: "the food bar and health bar need to be
## stacked not next to each other"), so this is the one true-bottom anchor the
## pair needs; the health bar above it derives its own position from this
## plate's real top instead of a second canvas-bottom margin.
##
## GATE3-HUD-SAFEAREA (Gate 2 evidence judge, `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`
## §6: "the `FOOD 100%` bar runs to about 15px from the bottom edge in every
## frame ... that is a ~2% margin; a 5% TV/handheld overscan crop takes it").
## A flat 6px margin reads as a fixed fraction of whichever canvas happens to
## be rendering -- ~0.6% of the Ally's real 1200-tall authored canvas at
## `aspect="expand"`, nowhere near the 5% overscan-safe floor every console
## and handheld UI guideline reserves, and CLAUDE.md names the Ally the
## primary target. `vitals_position()` now clears the LARGER of this fixed
## floor and `SAFE_AREA_BOTTOM_FRACTION` of the real canvas height, so the
## margin scales with the screen instead of being a constant that happened to
## read as adequate on whatever canvas it was last measured against.
const BOTTOM_VITALS_MARGIN := 6.0
const SAFE_AREA_BOTTOM_FRACTION := 0.05
## Vertical gap between the health plate and the satiety plate now that they
## are stacked, health above food. Reuses `UITokens.GAP`, the same small-gap
## token `PARTY_ACTIVE_GAP` above already borrows, rather than a new number.
##
## OWNER-HUD-INPUT-0903 supersedes OWNER-0902-HUD-TEAM-MENU's side-by-side
## arrangement here. That pass put the two plates beside each other because
## `vitals_position()` still anchored inside the SAME bottom-up left-stack
## chain the roster/creature panel use back then, and a tall roster reveal
## could run straight into the food bar sitting underneath it in that chain
## (owner playtest 2026-09-02, finding #11: "the team menu overruns the food
## bar"). Neither plate has been part of that chain since -- both
## `vitals_position()` and `player_health_bar_position()` derive purely from
## `canvas_height`, with no dependency on the creature panel or party strip's
## own height (see `_reflow_left_stack()`) -- so stacking them again does not
## reopen the original defect: `left_stack_bottom()` (where the roster reveal
## bottoms out) sits roughly 350px above where this pair now lives, at every
## supported aspect (`test_stacked_vitals_clear_the_left_stack_reveal`).
const VITALS_STACK_GAP := UITokens.GAP

const STAMINA_ARC_POS := Vector2(960.0 + 48.0, 540.0 - 160.0 * 0.5) ## centred-right of screen centre

## HUD-SCALE: 240 -> 184. The minimap is a permanently-present 2.78% of the
## canvas and is read as a shape (a triangle on a field), not as text, so it
## has no lettering floor to clear at all -- it was simply drawn at the same
## inflated scale as everything else. 184 keeps the player arrow and the
## marker dots at the same fraction of the map they had.
const MINIMAP_SIZE := Vector2(184.0, 184.0)

## HUD-SCALE: 420 -> 348, following the objective text down from
## `HUD_READABLE_FONT_SIZE` (38) to `HUD_SENTENCE_FONT_SIZE` (32). The width
## exists to hold a quest line without wrapping past its own box, so it tracks
## the font it was fitted to rather than being cut independently.
const OBJECTIVE_MAX_WIDTH := 348.0
## HUD-POPUP task 3: grown from 90 to hold the quest subtext at
## `HUD_READABLE_FONT_SIZE` (38) without wrapping past its own box -- see
## `_build_objective_block()`'s header for the rest of that fix.
## HUD-SCALE: 170 -> 152, and DERIVED rather than hand-tuned. A first cut to
## 124 was measured overflowing: the quest line still wraps to two lines at
## `OBJECTIVE_MAX_WIDTH`, and two lines at `HUD_SENTENCE_FONT_SIZE` render ~93
## px tall, which with the eyebrow row and the top inset needs ~149. Hard
## numbers on both axes are how the old 170 stopped tracking the fonts inside
## it, so the height now says what it is made of.
const OBJECTIVE_EYEBROW_ROW := 36.0
## Rendered height of one line at `HUD_SENTENCE_FONT_SIZE`, including the
## font's own leading. 1.45 is measured, not assumed: two lines at the
## previous 38px font rendered 109px (109 / 2 / 38 = 1.43), and at 32px they
## render 93 (93 / 2 / 32 = 1.45).
const SENTENCE_LINE_RATIO := 1.45
## HARNESS-HYGIENE-0903 (owner playtest finding, "Train with your team before
## the …"): raised 2 -> 4. `max_lines_visible` + `OVERRUN_TRIM_WORD_ELLIPSIS`
## (`_build_objective_block()` below) never lets the label overflow its own
## box, which is exactly why `smoke_objective_hint_card.gd`'s pre-existing
## "plate holds its text" check passed while this bug shipped: a WIDGET that
## cannot overflow can still silently drop the tail of a sentence into "…" if
## the cap is smaller than the wrap the real string needs, and nothing before
## this measured that gap. Measured directly against every `main` entry in
## `data/progression/objectives.json` at `OBJECTIVE_MAX_WIDTH`'s inner width,
## at both 1280x800 and 1920x1080 (`canvas_items` stretch keeps the logical
## layout identical between them, so the wrap count does not change with the
## window): 15 of 27 authored titles wrapped past 2 lines, up to 4 for "Reach
## South Bridge -- Team Tether holds the crossing." 4 is that measured worst
## case, not a guess -- `smoke_objective_hint_card.gd`'s
## `_check_no_authored_objective_title_is_clipped` re-measures this on every
## run, so a future title that needs a 5th line fails loudly here instead of
## shipping silently truncated.
const OBJECTIVE_LINES := 4
## How many lines the block RESERVES when the text does not need them, which is
## a different question from how many it will grow to hold.
##
## These were one number until 2026-09-03 and the block height was derived from
## the cap, so raising the cap 2 -> 4 to stop long titles truncating also raised
## the FLOOR: 168.8px -> 261.6px, reserved permanently, for every objective
## including the one-liners. On the 1280x800 handheld this game is built for
## that is a third of the screen height held open for a panel whose text says
## "Win the village tournament." The truncation fix was right and stays; this
## is the half of it that got carried along by the shared constant.
##
## `_layout_objective_block()` below already grows the panel past this floor
## whenever the text needs it (`maxf(OBJECTIVE_BLOCK_HEIGHT, ...)` against the
## capped text height), so the long titles that motivated the cap still get
## their four lines. Two is the measured two-line design height this block was
## fitted to and the value it shipped at before the cap moved.
const OBJECTIVE_MIN_LINES := 2
const OBJECTIVE_BLOCK_HEIGHT := OBJECTIVE_EYEBROW_ROW + OBJECTIVE_INSET \
	+ float(OBJECTIVE_MIN_LINES) * float(HUD_SENTENCE_FONT_SIZE) * SENTENCE_LINE_RATIO \
	+ OBJECTIVE_INSET
## Padding between the new backing panel's edge and the eyebrow/subtext
## labels inside it -- both were flush to the block's own right edge back
## when the block WAS the text's bounding box; now that a panel is drawn
## behind them, flush-right would touch the panel's own border.
## HUD-EMPHASIS: 12 -> 20. A blind critic's real render measured "MAIN
## STORY" and the first quest line running essentially wall-to-wall against
## the panel's right edge -- 12 authored px at this HUD's 0.667 canvas_items
## scale is ~8 physical px, thin enough at a right-aligned glyph's own side
## bearing to read as touching. Not yet clipping today, but one longer quest
## string away from it.
const OBJECTIVE_INSET := 20.0

## OBJECTIVE-HINT-ON-HUD (`HIST-036`, OP23-04 / OP23-09) -- the objective card.
##
## WHY THIS IS NOT A SECOND LINE IN THE OBJECTIVE BLOCK, which is the obvious
## place and the one the backlog assumed. `tools/_probe_objective_hint_height.gd`
## measures all 13 authored hints through `quest_log.gd::hint_text()` at the
## block's real inner width and font, and the backlog's estimate was optimistic:
##
##   inner 380, font 38 (the block today)  worst hint 318 px, 6 lines
##   inner 380, font 35 (legibility floor) worst hint 294 px
##   inner 544, font 38 (widened to the central third's edge) worst 265 px
##   inner 544, font 35 (both levers at once)                 worst 196 px
##
## The block's own top edge is fixed under the minimap at y 310 and the bottom
## dock begins at y 620, so 310 px is every pixel that exists there -- and the
## tracked line the hint stacks under is itself up to 159 px of that. Even both
## levers pulled at once (a wider block AND text at the smallest size this HUD
## is allowed to draw) overflows into the hotbar. There is no version of "under
## the objective" that fits, which is why this ships as a card instead of as
## the one-line change it looks like.
##
##   inner 800, font 38   worst hint 159 px
##   inner 1100, font 38  worst hint 106 px -- every hint, 2 lines, no
##                        font compromise and nothing shortened
##
## So the hint gets width instead of height, as a centred timed card.
## `smoke_prompt_hotbar_dock.gd`'s own rule is what makes the position legal: "persistent inventory shortcuts may
## frame that lane, but must not cover it; contextual prompts intentionally
## remain centred" -- this is contextual and transient, the same standing the
## region banner a few functions down already has.
## WIDTH IS THE CENTRE GUTTER, not a taste call, and it is the tighter of the
## two constraints on this card. Both HUD columns run the full height of the
## screen -- the left one is the party strip (rows 420 wide from
## `CREATURE_BLOCK_X` 56) or the creature panel standing in its place (real
## measured width 435, i.e. out to x 491); the right one is the minimap and the
## objective block, whose left edge is `1920 - HUD_INSET - OBJECTIVE_MAX_WIDTH`
## = x 1444. So a centred card clears both only up to
## 2 x (min(960 - 496, 1444 - 960) - GAP) = 900. A first render at 1140 -- the
## width the hint measurements alone wanted -- put the card's corner straight
## over the objective block's plate, which is the compositing defect this HUD
## keeps having, so the gutter wins and the hint wraps to four lines instead of
## two.
const OBJECTIVE_HINT_CARD_WIDTH := 900.0
## `UITokens.panel_box()`'s own content margin. The card is one paragraph on a
## plate; there is nothing inside it that needs the objective block's roomier
## `OBJECTIVE_INSET`, and at four lines of hint the band below has no 8px to
## spare on padding.
const OBJECTIVE_HINT_CARD_INSET := 16.0
## Placed off `_build_region_banner()`'s own bottom edge rather than at a hand
## tuned y, so a region announcement and an objective card can be up together
## -- entering a region is exactly the moment an objective is likely to advance
## -- and neither can be moved into the other by editing one of them. Small,
## because the band below is tight and two centred transient cards stacked
## close read as one column rather than as two floating boxes.
const OBJECTIVE_HINT_CARD_GAP_UNDER_BANNER := 10.0

## WHY THE CARD CARRIES THE HINT ALONE, and not the tracked line above it.
## Measured, not assumed. The band this card lives in is bounded above by the
## region banner's bottom (y 168) and below by the top of the bottom dock --
## which is NOT the dock's y 620 anchor: the dock is a bottom-aligned VBox and
## grows upward, and `smoke_prompt_hotbar_dock.gd`'s own worst case (hotbar
## message showing AND a wrapped two-line prompt) puts the hotbar panel's top
## edge at y 388. So the real band is 220 px.
##
## In the gutter the worst authored hint wraps to four lines (159 px) at this
## HUD's readable font, and to four lines at the legibility floor too, so the
## smaller font buys nothing and is not taken. That makes the card 191 px into
## a 220 px band. Adding the tracked line above it costs another 63 px and does
## not fit at all. The tracked line is on screen in the objective block at the
## same moment anyway, having just changed, and every authored hint is a
## complete self-contained sentence naming its own subject ("The old key lies
## in the grass a few steps off the road..."), so the card loses nothing by not
## repeating it.
##
## The clearance that leaves is about 19 px, against an adversarial dock state.
## That is thin, and it is why `smoke_objective_hint_card.gd` measures every
## authored hint against every other HUD widget's live rect rather than
## trusting these numbers: a longer hint authored later fails that test loudly
## instead of landing on the hotbar in someone's playtest.

## How long a revealed card stays up: a fixed acquisition cost plus real
## reading time. 200 wpm is the low end of comfortable adult prose reading,
## which is the right end to size a game HUD from, and the seconds in front of
## it are the glance -- the player has to notice the card before they start
## reading it. Per-hint rather than a constant, because a window long enough
## for the opening's 21-word key-and-gate hint would leave a 9-word one sitting
## on screen well after it had been read.
const OBJECTIVE_HINT_SECONDS_BASE := 2.5
const OBJECTIVE_HINT_SECONDS_PER_WORD := 0.3

## OP21-11: the owner's own words were "should sit under the hotbar" — moved
## from RG3's original upper-left placement into `Root/BottomDock`'s
## VBoxContainer (see the .tscn's own long comment on why that container
## exists at all: it is the one place on this HUD where two variable-height
## rows genuinely cannot overlap, because Godot lays them out in sequence
## rather than at hand-tuned offsets). The legend is inserted between
## `HotbarPanel` and `Prompt` in `_build_exploration_legend()` below, so it
## always renders directly beneath the hotbar chips and directly above the
## contextual prompt — no separate position constant needed any more; the
## VBox derives it every frame from both neighbours' real heights.
##
## Glyph/font size, not position, is OP21-11's other half: the legend used to
## draw its glyphs at 24px, smaller than `input_glyph.gd::icon()`'s own
## documented floor ("28->36 was the smallest step that read clearly" for a
## harder glyph than any of these five carry) and the worst offender on the
## whole HUD at the project's 1920x1080 authoring scale. At the Ally's actual
## 1280x800 (canvas_items stretch, scale 1280/1920 = 0.667), that was ~16
## physical px. 44px authored -> ~29 physical px, comfortably past the
## established floor with margin for "more legible", not just "not the worst".
## HUD-SCALE (owner playtest 2026-08-28, "the hud on screen is way too big",
## the SECOND report). 66/36 -> 26/26.
##
## The 66/36 pair above was arrived at by multiplying a target through a
## `1280/1920 = 0.667` content scale. `scripts/ui/hud_scale.gd`'s header sets
## out at length why that scale is not real -- the Ally is 1920x1080, the
## authored canvas is 1920x1080, and `canvas_items` stretch makes an authored
## pixel a fixed fraction of the PANEL at any render resolution anyway. The
## practical effect was a 1.5x inflation applied to a floor that was already
## met, and this legend paid the most for it: at 66 authored px its glyphs
## subtend 40.7 arcmin at arm's length, which is over twice the size at which
## the same badge art resolves cleanly.
##
## 26 is `HUD_SCALE.GLYPH_ARCMIN` (16.0') and `GLANCE_CAP_ARCMIN` (11.0')
## respectively -- both measured floors, not guesses; see
## `tools/_probe_glyph_ladder.gd` for the render the glyph floor comes from.
const LEGEND_GLYPH_PX := 26
const LEGEND_FONT_SIZE := 26
## Shared local floor for every other micro-label this file draws that the
## same critic measured at 9px -- "ACTIVE COMPANION", "Lv 1"/"GROUND", the
## hotbar item count. Deliberately NOT `UITokens.FONT_TINY`: that constant is
## shared by a dozen other screens this lane does not own (menu tabs, combat,
## the minimap), so bumping it here would move text this task never measured.
## HUD-SCALE: 38 -> 26, and the constant is now DERIVED rather than asserted.
## 38 puts a cap height of 16.4 arcmin on every tag on this HUD -- newspaper
## body text, at reading distance, for the string "Lv 1". `HUD_SCALE`'s
## GLANCE tier is the right one for a label you recognise rather than read;
## the sentence-shaped text on this HUD (the objective line) takes
## `HUD_SENTENCE_FONT_SIZE` below instead, so the two stop sharing one number.
const HUD_READABLE_FONT_SIZE := 26
## Text on this HUD that is an actual sentence and is parsed rather than
## recognised. See `HUD_SCALE.SENTENCE_CAP_ARCMIN`.
const HUD_SENTENCE_FONT_SIZE := 32
## RichTextLabel's `fit_content` measures height against its CURRENT width,
## and a freshly-built PanelContainer with no width hint of its own has none
## yet -- the label wrapped to a near-zero column and reported an absurd
## 1400+px content height the first time this ran. A fixed minimum size, the
## same approach the old top-left panel used, sidesteps that: wide enough for
## all five entries at the enlarged glyph/font (measured against "Change
## Creature", the longest label, plus its two switch-direction glyphs) with
## room to spare. Height is the 44px glyph plus `UITokens.panel_box()`'s own
## 16px top+16px content margin (32px total) -- `_build_exploration_legend`
## below deliberately adds NO further vertical margin on top of that; this
## exact double-margin mistake already shipped once (see the function's own
## history comment) and squeezed the glyph row down to an 8px label.
## HUD-SCALE: 1700x112 -> 940x64. This was the single largest widget on the
## HUD -- 9.18% of the canvas, measured by `tools/_measure_hud_footprint.gd`,
## for a bar that reminds the player of four buttons. Its width was a hand-fitted
## minimum for the entries at the old 66px glyph and 36px font; both are 26 now,
## so the same five entries need roughly 55% of the width. Height is the 26px
## glyph plus `UITokens.panel_box()`'s own 16+16px margins, which is 58, rounded
## up to 76 for the label's own line leading -- the SAME derivation the old 112
## used (44 + 32 + slack), not a new one.
##
## 76 rather than 64, and that 12px is measured: a first cut to 64 left the
## label 32px of inner height against a real `get_content_height()` of 36 for
## a 26px glyph row, and `smoke_exploration_legend.gd::_check_authored_layout`
## failed on exactly that clip. Godot's line box for an inline image is taller
## than the image; the old 112 carried the same ~10px of slack over 44 + 32.
##
## Still a floor rather than a cap: `SHRINK_END` + `fit_content` means a longer
## entry set grows the panel instead of clipping it, which is what
## `smoke_exploration_legend.gd` checks.
const LEGEND_SIZE := Vector2(940.0, 76.0)

## GATE3-HUD-INTERACT: the interact pill's own box width used to be a flat
## `custom_minimum_size.x = 640` in the .tscn regardless of what it said --
## Godot does not shrink a `fit_content` `RichTextLabel`'s WIDTH to its text
## when autowrap is on, only its height, so "Chop" (measured 140px of
## content) and "Put Thunderbristle Junior away" (541px) reserved the exact
## same 640px of world behind them. `_fit_prompt_pill()` now measures each
## prompt's real content width (via `_prompt_measure`, an off-screen scratch
## label carrying the same font size and bbcode) and sizes the pill to that,
## clamped between these two. `PROMPT_MIN_WIDTH` is a floor only the emptiest
## prompts ("Chop", 140+32=172px measured) would ever hit. `PROMPT_MAX_WIDTH`
## keeps the pill's OLD fixed width as a ceiling -- the widest realistic
## single-verb prompt measures 541+32=573px, so this still never wraps an
## ordinary prompt, and `smoke_prompt_hotbar_dock.gd`'s combined
## message+long-name case (want: wraps to two lines) still hits this ceiling
## exactly as before.
const PROMPT_MIN_WIDTH := 200.0
const PROMPT_MAX_WIDTH := 640.0
## `prompt_box.content_margin_left/right` in `_ready()` and the width
## `_fit_prompt_pill()` reserves for them share this constant so the two
## can never drift the way two independently hand-copied `16.0`s could.
const PROMPT_CONTENT_MARGIN_X := 16.0
const PROMPT_SCRATCH_WIDTH := 2000.0

const VITALS_CONFIG_PATH := "res://data/config/vitals.json"
const DEFAULT_MAX_BUFF_CHIPS := 3
const BUFF_CHIP_SIZE := 20.0  ## HUD-SCALE: 28 -> 20, matching PARTY_PIP_SIZE as it always has.
## HUD-POPUP task 2: 18 -> 28, matching `BUFF_CHIP_SIZE`'s own footprint. A
## blind critic measured the old 18-authored pips at ~13 physical px with a
## ~2px selection ring, "a squint at arm's length." See `_update_party_pips()`'s
## own header for the rest of this task's pip work.
## HUD-SCALE: 28 -> 20. A pip is a dot with a ring, read as a count and a
## position rather than as a symbol, so `GLYPH_ARCMIN`'s lettering floor does
## not apply; 20 authored px is still 12.3 arcmin, comfortably resolvable.
const PARTY_PIP_SIZE := 20.0

const HP_DANGER_BELOW := 0.30
const HP_PULSE_SPEED := 3.0
const HP_PULSE_DEPTH := 0.15

@export var player_path: NodePath
@export var arbiter_path: NodePath

const STUCK_AXES_HINT_AFTER := 3.0
const STUCK_AXES_EPSILON := 0.05

var _player: CharacterBody3D = null
var _arbiter: Node = null
var _game: Node = null
var _party: RefCounted = null

var _since_readout := 0.0
var _peak_fall := 0.0
var _last_damage := 0.0
var _debug_level := DEBUG_OFF

var _frame_ms := PackedFloat32Array()
var _frame_head := 0
var _frame_filled := 0

var _hardware_line := ""

var _pad_connected_for := 0.0
var _max_raw_axis_seen := 0.0

@onready var _root: Control = $Root
@onready var _prompt_label: RichTextLabel = $Root/BottomDock/Prompt
## GATE3-HUD-INTERACT: off-screen scratch label `_fit_prompt_pill()` measures
## against. Never added to `BottomDock` and never visible -- it exists only
## to answer "how wide does this text want to be with nothing constraining
## it," which `_prompt_label` itself cannot answer once autowrap is active.
var _prompt_measure: RichTextLabel = null
@onready var _debug_readout: Label = $Root/DebugReadout
@onready var _hotbar_chips: Array[PanelContainer] = [
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot1,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot2,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot3,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot4,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot5,
]
@onready var _hotbar_slots: Array[RichTextLabel] = [
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot1/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot2/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot3/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot4/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot5/Label,
]
@onready var _hotbar_panel: PanelContainer = $Root/BottomDock/HotbarPanel
@onready var _hotbar_message: Label = $Root/BottomDock/HotbarPanel/Margin/Layout/Message

var _hotbar_last_text: Array[String] = ["", "", "", "", ""]
var _hotbar_message_until := 0.0

## --- active-creature block --------------------------------------------------------

var _creature_block: Control = null
var _creature_panel: PanelContainer = null
var _creature_header: Label = null
var _creature_content: Control = null
var _creature_chip: ColorRect = null
var _creature_portrait: TextureRect = null
var _creature_portrait_path := ""
var _creature_name_label: Label = null
var _creature_level_label: Label = null
var _creature_type_label: Label = null
var _creature_hp_bar: ProgressBar = null
var _creature_hp_fill: StyleBoxFlat = null
var _creature_energy_bar: ProgressBar = null
var _creature_energy_fill: StyleBoxFlat = null
var _creature_no_creature_label: Label = null
var _creature_block_has_creature_last := true ## forces the first _update_creature_block to write
var _creature_icon: TextureRect = null
var _creature_hp_value_label: Label = null
var _creature_header_out_last := false ## -1-state forces the first header write
var _creature_header_has_creature_last := false

## T3-INSTALL, B1: the active creature's tonic buffs (`creature_instance.gd::
## apply_buff`/`active_buffs`) had no HUD indicator anywhere -- a player could
## drink a tonic, see the one-time toast, and then never know the buff was
## still running or had ended. Same chip visual as `_buff_chips` above.
var _creature_buff_chips: Array[Panel] = []
var _creature_buff_chip_labels: Array[Label] = []
var _creature_buff_overflow_label: Label = null

## Small always-on "how many, who's active" readout, five pips wide -- never
## more, never fewer, same "five rows always exist" discipline
## `party_strip.gd`'s own header documents, just persistent instead of a
## reveal-and-fade. Added because the full `party_strip.gd` reveal only shows
## for `UITokens.T_PARTY_FADE` seconds after a change: a blind critic reading
## an idle frame between changes saw ONE card (this block) and no five-slot
## roster anywhere, with the five-slot item hotbar sitting right below it as
## the only other five-of-anything on screen -- exactly the wrong thing to
## mistake for the team. This row answers "how many/which/what would cycling
## do" without text, at all times, not just mid-transition.
var _party_pips: Array[Panel] = []
var _party_pip_boxes: Array[StyleBoxFlat] = []

## --- party strip --------------------------------------------------------------

var _party_strip: Control = null
var _party_strip_script: Script = null
var _party_strip_last_index := -999
var _party_strip_last_revision := -999
## OP21-12: the last active creature's name, so a later cycle can say "Willow
## → Ashcap" instead of just lighting up a new row.
var _party_strip_last_active_label := ""
## HUD-POPUP: see `_update_party_strip()`'s own header for why this needs its
## own change-guard input alongside `_party_strip_last_index`/`_revision`.
var _party_strip_last_active_out := true

## --- player vitals cluster ----------------------------------------------------

## T3-INSTALL, B1: `vitals.json`'s `buffs.max_visible_icons` used to have no
## reader anywhere -- both this row and the creature buff row below now size
## themselves from it instead of a hardcoded 3, loaded once in `_ready()`
## before either row is built.
var _max_buff_chips := DEFAULT_MAX_BUFF_CHIPS

var _vitals_cluster: Control = null
## HUD-BACKLOG-20: the player's HP icon/bar/value, split out of
## `_vitals_cluster` into their own bottom-left-anchored widget. See
## `_build_player_health_bar()`.
var _health_bar_cluster: Control = null
var _buff_chips: Array[Panel] = []
var _buff_chip_labels: Array[Label] = []
var _buff_overflow_label: Label = null
var _hp_icon: TextureRect = null
var _hp_bar: ProgressBar = null
var _hp_fill: StyleBoxFlat = null
var _hp_value_label: Label = null
## GATE3-HUD-CONTRAST: opaque backing behind `_hp_value_label`'s digits -- see
## `_style_meter_value_chip()`'s own header for why the label's font colour
## alone cannot fix this.
var _hp_value_chip: Panel = null
var _satiety_bar: ProgressBar = null
var _satiety_caption_label: Label = null
var _satiety_value_label: Label = null
var _satiety_value_chip: Panel = null
var _satiety_state_label: Label = null

var _last_health_value := -1.0
var _health_flash_timer := 0.0
var _hp_pulse_time := 0.0

## --- stamina arc ---------------------------------------------------------------

var _stamina_arc: Control = null
var _stamina_icon: TextureRect = null
var _last_stamina_fraction := -1.0

## --- minimap (owned by a concurrent pass; mounted defensively) ----------------

var _minimap: Control = null
var _minimap_baked := false

## --- objective block ------------------------------------------------------------

var _objective_text_label: Label = null
var _objective_eyebrow_label: Label = null
## The whole objective panel, so `_update_objective()` can hide it when there is
## no objective left to track. See that function's own comment.
var _objective_block: Control = null
var _objective_last_text := ""
## The block's backing panel. Held as a field because it is the visible edge --
## `_update_objective()`'s own comment already notes that the panel, not the
## text, is what the player sees -- and `_layout_objective_block()` has to
## resize it with the block whenever the tracked line rewraps.
var _objective_backing: PanelContainer = null

## OBJECTIVE-HINT-ON-HUD. The card, its label, its backing plate and its reveal
## deadline -- the deadline in the same `Time.get_ticks_msec()` seconds
## `_region_banner_until` already uses, because this HUD already had a
## timed-reveal idiom and a second one for the same job would be worse than a
## shared one. 0.0 means "not revealed" and the card is hidden.
var _objective_hint_card: Control = null
var _objective_hint_card_backing: PanelContainer = null
var _objective_hint_label: Label = null
var _objective_hint_until := 0.0

## --- region banner ---------------------------------------------------------------

var _region_banner: Label = null
var _region_banner_until := 0.0
## PROGRESSION-VISIBLE: the Moment banner (prompt 73 §2.2) -- a level-up or
## a bond milestone, top-centre under the region card, ~3s, queued behind a
## fight and behind any story modal, two within `moment_collapse_seconds`
## sharing one plate. Passive: a PanelContainer of Labels on LAYER_HUD, so it
## can never take focus from a menu or a dialogue.
var _moment_banner: PanelContainer = null
var _moment_title: Label = null
var _moment_detail: Label = null
var _moment_also: Label = null
var _moment_queue: Array = []
var _moment_feed_seq: int = 0
var _moment_until := 0.0
var _moment_shown_at := 0.0
var _moment_cooldown_until := 0.0
var _moment_shown_count := 0
var _last_moment: Dictionary = {}
var _party_strip_last_feed_revision := -999
var _creature_xp_label: Label = null

## --- day/time readout (owner playtest 2026-08-30B item 19) ----------------------

## `MeadowsPlayground`'s own clock, looked up defensively the same way the
## minimap's owning script is -- a capture rig or an isolated test scene may
## have no `WorldLook` at all, and this readout should just stay blank rather
## than crash. Re-checked with `is_instance_valid()` each frame the same way
## `_refresh_game_ref()` re-checks `_game`, since neither node is guaranteed
## to exist yet the first time `_ready()` runs.
var _world_look: Node = null
var _daytime_label: Label = null

## --- persistent exploration legend (RG3) ---------------------------------------

var _exploration_legend: PanelContainer = null
var _exploration_legend_label: RichTextLabel = null
var _legend_last_gamepad := false
var _legend_last_party_revision := -999
## Whether the contextual prompt was naming `creature_recall` when the legend
## was last drawn. Part of the redraw key: without it a stale Call Out entry
## would survive until the party or the input device changed.
var _legend_last_prompt_owned_recall := false
## Whether the active creature was standing in the world when the legend was
## last drawn. Part of the redraw key for the same reason: the recall entry
## reads "Put Away" or "Call Out" off exactly this.
var _legend_last_creature_was_out := false
var _legend_was_drawn := false

## --- left-column reflow (HUD-LAYOUT) --------------------------------------------

## Sentinel below any real canvas height, so the first `_reflow_left_stack()`
## call after `_ready()` always runs once, whatever `_root.size.y` turns out
## to be by then.
var _left_stack_canvas_h := -1.0
var _left_stack_creature_h := -1.0
var _left_stack_creature_w := -1.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
	elif _player.has_signal("landed"):
		_player.connect("landed", _on_landed)

	_arbiter = get_node_or_null(arbiter_path)
	if _arbiter != null and _arbiter.has_signal("prompt_changed"):
		_arbiter.connect("prompt_changed", _on_prompt_changed)

	_load_buff_config()
	_build_creature_block()
	_mount_party_strip()
	_build_vitals_cluster()
	_build_player_health_bar()
	_mount_stamina_arc()
	_mount_minimap()
	_build_objective_block()
	_build_objective_hint_card()
	_build_region_banner()
	_build_moment_banner()
	_build_daytime_readout()
	_build_exploration_legend()
	_style_hotbar()

	# Placed FROM the hotbar rather than beside it. `resized` is the hook that
	# matters: the panel's height changes whenever its message row appears, and
	# nothing else fires on that.

	# HUD-EMPHASIS: a blind critic named the contextual prompt ("Call out
	# <name>", the only place the player is told the button that puts a
	# creature into their hands) as drawn "with no backing plate directly
	# over grass, sitting between two plated panels" (the hotbar above it,
	# the exploration legend below it in the same `BottomDock` stack). The
	# `normal` stylebox is `RichTextLabel`'s own background item -- this adds
	# a plate without restructuring the scene tree or touching
	# `fit_content`'s own auto-sizing, which just grows to include the new
	# stylebox's content margins.
	#
	# GATE3-HUD-INTERACT (Gate 2 evidence judge, `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`
	# §6: "the `Try the bridge gate` pill sits directly over the bridge gate
	# the objective is telling you to look at"). This box's ACCENT border now
	# also marks it as the interact tier (see `_style_meter_value_chip()`'s
	# sibling reasoning on tiering HUD surfaces) -- `panel_box_accent()`'s own
	# header covers why TEAL.
	var prompt_box := UITokens.panel_box_accent(UITokens.TEAL)
	prompt_box.content_margin_left = PROMPT_CONTENT_MARGIN_X
	prompt_box.content_margin_top = 6.0
	prompt_box.content_margin_right = PROMPT_CONTENT_MARGIN_X
	prompt_box.content_margin_bottom = 6.0
	_prompt_label.add_theme_stylebox_override("normal", prompt_box)
	_build_prompt_measure()

	UITokens.make_text_legible(_prompt_label)
	UITokens.make_text_legible(_hotbar_message)
	UITokens.make_text_legible(_region_banner)
	for slot in _hotbar_slots:
		UITokens.make_text_legible(slot)

	_frame_ms.resize(FRAME_WINDOW)
	_hardware_line = "%s | %s | driver %s" % [
		RenderingServer.get_video_adapter_name(),
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")),
		"/".join(OS.get_video_adapter_driver_info()),
	]

	# PERF-ROG / OP23-01. The overlay has to be reachable on the device the
	# owner actually plays on, and F3 is not: the ROG Ally is a handheld with a
	# controller, and the owner's authored controller map (2026-08-22) spends
	# every pad button on a gameplay verb with held chords banned, so there is
	# no spare press to give this. A config flag is the honest answer -- flip
	# `debug_overlay_on_boot` in data/config/performance.json, build, and the
	# readout is on from the first frame of the session the owner plays.
	# F3 still cycles it for anyone on a keyboard.
	var perf_cfg: Dictionary = PERF_CONFIG.config()
	if bool(perf_cfg.get("debug_overlay_on_boot", false)):
		_debug_level = clampi(int(perf_cfg.get("debug_overlay_level", DEBUG_PERF)), DEBUG_PERF, DEBUG_FULL)
	PERF_TRACE.set_enabled(_debug_level != DEBUG_OFF)
	_debug_readout.visible = _debug_level != DEBUG_OFF

	# Seeded from the arbiter rather than blanked, because `prompt_changed`
	# only fires on a CHANGE: if the arbiter published before this HUD
	# connected, waiting for the next edge would leave the prompt blank while
	# the player stands in front of something interactable.
	_prompt_label.text = "" if _prompt_belongs_to_combat() \
			else (str(_arbiter.call("prompt")) if _arbiter != null else "")
	_fit_prompt_pill()

	# Structure is finished: outline/shadow every Label and RichTextLabel this
	# file just built, in one pass, rather than one make_text_legible call per
	# widget scattered through the builders above.
	UITokens.make_text_legible(_root)
	_strengthen_objective_contrast()
	_soften_vitals_contrast()
	_reflow_left_stack()


## GATE3-HUD-HIERARCHY (Gate 2 evidence judge, `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`
## §6: "objective / action / interact hierarchy does not separate ... every
## element is the same dark-navy rounded panel at the same opacity"). The
## hotbar and the exploration legend beneath it are the PERSISTENT
## capability row -- what the player can always do -- and are the one tier
## of the three that is never telling the player anything urgent, so they
## get `panel_deep_box()`, the token this file's own header already
## documents as "a surface that wants to read as further back / behind
## everything else on screen." The interact pill (`_prompt_label`, styled in
## `_ready()`) and the objective card (`_build_objective_block()`) each get
## their own accent border instead, so all three tiers are visually distinct
## rather than one repeated dark-navy box.
func _style_hotbar() -> void:
	$Root/BottomDock/HotbarPanel.add_theme_stylebox_override("panel", UITokens.panel_deep_box())
	for chip in _hotbar_chips:
		chip.add_theme_stylebox_override("panel", UITokens.slot_box(false))


## Builds `_prompt_measure`: see that field's own header for why it exists.
func _build_prompt_measure() -> void:
	_prompt_measure = RichTextLabel.new()
	_prompt_measure.name = "PromptMeasure"
	_prompt_measure.bbcode_enabled = true
	_prompt_measure.fit_content = true
	_prompt_measure.scroll_active = false
	_prompt_measure.visible = false
	_prompt_measure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_measure.custom_minimum_size = Vector2(PROMPT_SCRATCH_WIDTH, 0.0)
	_prompt_measure.size = Vector2(PROMPT_SCRATCH_WIDTH, 200.0)
	_prompt_measure.add_theme_font_size_override(
		"normal_font_size", _prompt_label.get_theme_font_size("normal_font_size")
	)
	_root.add_child(_prompt_measure)


## GATE3-HUD-INTERACT: resizes the interact pill to what `_prompt_label`'s
## CURRENT text actually needs -- see `PROMPT_MIN_WIDTH`'s own header for the
## measurements this is built on. Called every time the prompt text changes
## (`_on_prompt_changed()` and the seed assignment in `_ready()`), never every
## frame -- `prompt_changed` only fires on an edge, so this is cheap.
func _fit_prompt_pill() -> void:
	if _prompt_label == null or _prompt_measure == null:
		return
	if _prompt_label.text.is_empty():
		_prompt_label.custom_minimum_size = Vector2(PROMPT_MIN_WIDTH, 0.0)
		return
	_prompt_measure.text = _prompt_label.text
	var natural := _prompt_measure.get_content_width()
	var target := clampf(
		natural + PROMPT_CONTENT_MARGIN_X * 2.0, PROMPT_MIN_WIDTH, PROMPT_MAX_WIDTH
	)
	_prompt_label.custom_minimum_size = Vector2(target, 0.0)


# --- active-creature block ----------------------------------------------------------


## HUD-LAYOUT: rebuilt from hand-placed `.position`/`.size` offsets onto real
## containers. Every element that used to be told its own pixel rect now
## only says how it wants to relate to its NEIGHBOURS -- a `PanelContainer`
## whose only fixed number is a width FLOOR (`CREATURE_BLOCK_MIN_WIDTH`, not
## a cap) around a `VBoxContainer` of rows, each row itself an `HBoxContainer`
## where it has more than one element. This is a direct fix for a concrete,
## reproduced defect, not a style preference: at `HUD_READABLE_FONT_SIZE`
## (bumped 24->38 by an earlier pass for legibility, correctly, but never
## paired with bigger rects for the same text), the OLD fixed-offset layout
## had "READY TO CALL OUT" overrunning its 324px label box, the five party
## pips hand-placed at a fixed y=32 landing ON TOP OF that overrun text, the
## HP value label's 16px-tall box unable to hold its own 38px font and
## spilling below the panel's bottom edge, and the level/HP rows close
## enough together (34 and 68) that the HP bar's fill visibly clipped the
## bottom of "Lv 1". None of those are possible once each row's height comes
## from its own children's real minimum size instead of a guessed offset --
## a `VBoxContainer` cannot lay a later row on top of an earlier one, the
## same guarantee `Root/BottomDock` already relies on for the hotbar/legend/
## prompt stack (see that node's own long comment in the .tscn).
##
## Portrait chip, label()/level, HP bar, an energy strip shown only while
## there IS energy to show, and a type tag — or, with no active creature, a dim
## "No creature out" chip. Species tint comes from `CreatureSpecies.placeholder()`, the
## same lookup `party_strip.gd`'s caller (this file, below) uses, so the two
## widgets can never tint the same creature two different colours.
func _build_creature_block() -> void:
	_creature_block = Control.new()
	_creature_block.name = "CreatureBlock"
	_creature_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_creature_block)

	_creature_panel = PanelContainer.new()
	_creature_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_panel.custom_minimum_size = Vector2(CREATURE_BLOCK_MIN_WIDTH, 0.0)
	_creature_panel.add_theme_stylebox_override(
		"panel", UITokens.panel_box(UITokens.BG_DEEP, Color(UITokens.TEAL, 0.72))
	)
	_creature_block.add_child(_creature_panel)

	# `panel_box()` already contributes 16px of content margin on every side
	# via the stylebox itself -- a `PanelContainer` applies that automatically
	# to whatever it holds, so no separate `MarginContainer` belongs here (the
	# exact double-margin trap `_build_exploration_legend()`'s own comment
	# already names for the legend panel).
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	_creature_panel.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	_creature_icon = TextureRect.new()
	_creature_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_icon.texture = load(ICON_CREATURES)
	_creature_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_creature_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_creature_icon.custom_minimum_size = Vector2(24.0, 24.0)
	_creature_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.add_child(_creature_icon)

	_creature_header = Label.new()
	_creature_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_header.text = "ACTIVE COMPANION"
	_creature_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# NOT `clip_text = true` -- a first version of this rebuild set it,
	# meaning to guarantee the text stayed inside the panel, and instead
	# discovered the opposite failure a real capture caught: `clip_text`
	# tells a Label's MINIMUM size to ignore its own text width, so nothing
	# ever asked the panel to grow past `CREATURE_BLOCK_MIN_WIDTH`, and
	# "READY TO CALL OUT" (longer than "ACTIVE COMPANION") clipped to "READY
	# TO CALL C". Leaving text un-clipped lets its real width become part of
	# the row's -- and therefore the panel's -- honest minimum size, which is
	# what actually keeps it on-screen instead of truncated.
	_creature_header.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	_creature_header.add_theme_color_override("font_color", UITokens.TEAL_SOFT)
	header_row.add_child(_creature_header)

	## Five persistent pips, on their own row below the header text -- see
	## `_party_pips`'s own declaration for why this exists alongside the
	## transient `party_strip.gd` reveal rather than instead of it. A row of
	## its own, laid out by `HBoxContainer`, so it can never land on top of
	## the header text above it regardless of how wide that text gets.
	var pip_row := HBoxContainer.new()
	pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip_row.alignment = BoxContainer.ALIGNMENT_END
	pip_row.add_theme_constant_override("separation", 6)
	vbox.add_child(pip_row)
	for i in 5:
		var pip := Panel.new()
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.custom_minimum_size = Vector2(PARTY_PIP_SIZE, PARTY_PIP_SIZE)
		var pip_box := StyleBoxFlat.new()
		pip_box.bg_color = Color(UITokens.TEXT_MUTED, 0.35)
		pip_box.border_width_left = 1
		pip_box.border_width_top = 1
		pip_box.border_width_right = 1
		pip_box.border_width_bottom = 1
		pip_box.border_color = UITokens.BORDER
		pip_box.corner_radius_top_left = 3
		pip_box.corner_radius_top_right = 3
		pip_box.corner_radius_bottom_left = 3
		pip_box.corner_radius_bottom_right = 3
		pip.add_theme_stylebox_override("panel", pip_box)
		_party_pip_boxes.append(pip_box)
		_party_pips.append(pip)
		pip_row.add_child(pip)

	_creature_content = VBoxContainer.new()
	_creature_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_content.add_theme_constant_override("separation", 6)
	vbox.add_child(_creature_content)

	var info_row := HBoxContainer.new()
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_theme_constant_override("separation", 12)
	_creature_content.add_child(info_row)

	# 56x56, up from 40x40 -- a blind critic called the old ~28-physical-px
	# portrait "too small to identify a species at arm's length", and a
	# portrait reads faster than the name text beside it once it is big
	# enough to actually show the silhouette. Wrapped in its own fixed-size
	# Control: the chip and portrait are meant to overlay each other (the
	# portrait's transparent surround shows the species-tinted chip behind
	# it), which is the one place in this panel two children legitimately
	# share a rect on purpose rather than by accident.
	var portrait_slot := Control.new()
	portrait_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_slot.custom_minimum_size = Vector2(56.0, 56.0)
	info_row.add_child(portrait_slot)

	_creature_chip = ColorRect.new()
	_creature_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_chip.position = Vector2(0.0, 0.0)
	_creature_chip.size = Vector2(56.0, 56.0)
	portrait_slot.add_child(_creature_chip)

	_creature_portrait = TextureRect.new()
	_creature_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_portrait.position = Vector2(3.0, 3.0)
	_creature_portrait.size = Vector2(50.0, 50.0)
	_creature_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_creature_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_slot.add_child(_creature_portrait)

	var info_col := VBoxContainer.new()
	info_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_col.add_theme_constant_override("separation", 2)
	info_row.add_child(info_col)

	# Bumped to match the rest of this panel's text (was `FONT_BODY`, 26) --
	# a blind critic separately measured the creature's own NAME at ~14px
	# physical cap height, just under the ~16px arm's-length floor every
	# other label on this panel was already raised to clear.
	_creature_name_label = Label.new()
	_creature_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Not clipped, same reasoning as the header above -- the panel is already
	# wide enough to fit the longer "READY TO CALL OUT"/HP-value strings, so
	# a player-chosen name has plenty of room without needing its own escape
	# hatch that would otherwise risk silently truncating it.
	_creature_name_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	info_col.add_child(_creature_name_label)

	var level_type_row := HBoxContainer.new()
	level_type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_type_row.add_theme_constant_override("separation", 16)
	info_col.add_child(level_type_row)

	_creature_level_label = Label.new()
	_creature_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_level_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	_creature_level_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	level_type_row.add_child(_creature_level_label)

	# PROGRESSION-VISIBLE (prompt 73 §5): "the player can tell how close a
	# creature is to the next level from the world HUD". One short line beside
	# the level -- "34 to Lv 9" -- in the glance tier, warming to WARNING when
	# a level is one fight away.
	_creature_xp_label = Label.new()
	_creature_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_xp_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_creature_xp_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	level_type_row.add_child(_creature_xp_label)

	_creature_type_label = Label.new()
	_creature_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_type_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	level_type_row.add_child(_creature_type_label)

	# HP bar and its "78 / 120" readout sit SIDE BY SIDE in one row instead
	# of the old bar-with-a-label-floating-past-its-own-rect: the bar takes
	# whatever width is left (`SIZE_EXPAND_FILL`), the value gets its own
	# fixed column, and an `HBoxContainer` cannot let either draw outside the
	# panel the way a hand-placed `position.x = 246` with a 94px-wide label
	# box could once the font inside it grew.
	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override("separation", 10)
	_creature_content.add_child(hp_row)

	_creature_hp_bar = ProgressBar.new()
	_creature_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_hp_bar.custom_minimum_size = Vector2(160.0, 18.0)
	_creature_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_creature_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_creature_hp_bar.show_percentage = false
	_creature_hp_bar.min_value = 0.0
	_creature_hp_bar.max_value = 1.0
	_creature_hp_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_creature_hp_fill = UITokens.fill_box(UITokens.HP_GREEN)
	_creature_hp_bar.add_theme_stylebox_override("fill", _creature_hp_fill)
	hp_row.add_child(_creature_hp_bar)

	# Numeric readout beside the bar -- a blind critic read the bare fill as
	# "an unlabeled ~55%-filled green bar [that] reads as wrong at a glance"
	# on a fresh Lv 1 creature with nothing wrong with it. The player's own
	# vitals cluster already pairs its bar with a "284 / 320" label; this
	# gives the companion's HP the same treatment instead of a bare fill.
	_creature_hp_value_label = Label.new()
	_creature_hp_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_hp_value_label.custom_minimum_size = Vector2(100.0, 0.0)
	_creature_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_creature_hp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# NOT `clip_text = true` -- a real capture caught this exact label
	# reading as "/ 120" instead of "120 / 120": `clip_text` combined with
	# RIGHT alignment clips from the START of the string (the end stays
	# anchored to the box's right edge), so a value wider than the 100px
	# floor above silently ate its own leading digits instead of growing the
	# row -- the same class of mistake `_creature_header`'s own comment
	# describes, just on the other side of the row.
	_creature_hp_value_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	_creature_hp_value_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	hp_row.add_child(_creature_hp_value_label)

	_creature_energy_bar = ProgressBar.new()
	_creature_energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_energy_bar.custom_minimum_size = Vector2(0.0, 6.0)
	_creature_energy_bar.show_percentage = false
	_creature_energy_bar.min_value = 0.0
	_creature_energy_bar.max_value = 1.0
	_creature_energy_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_creature_energy_fill = UITokens.fill_box(UITokens.TEAL)
	_creature_energy_bar.add_theme_stylebox_override("fill", _creature_energy_fill)
	_creature_content.add_child(_creature_energy_bar)

	_build_creature_buff_row()

	_creature_no_creature_label = Label.new()
	_creature_no_creature_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_no_creature_label.text = "No creature out"
	_creature_no_creature_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_creature_no_creature_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	_creature_no_creature_label.visible = false
	vbox.add_child(_creature_no_creature_label)


## T3-INSTALL, B1. Same chip-row visual as `_build_buff_row()`, but laid out
## in an `HBoxContainer` rather than by hand: `_creature_content` is already a
## `VBoxContainer`, so a child added here simply stacks below the energy bar
## instead of needing its own manually-tracked x/y.
func _build_creature_buff_row() -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UITokens.GAP)
	_creature_content.add_child(row)

	for i in _max_buff_chips:
		var chip := Panel.new()
		chip.mouse_filter = Control.MOUSE_FILTER_PASS  ## needs to receive the tooltip
		chip.custom_minimum_size = Vector2(BUFF_CHIP_SIZE, BUFF_CHIP_SIZE)
		var box := StyleBoxFlat.new()
		box.bg_color = UITokens.TEAL
		box.corner_radius_top_left = UITokens.RADIUS_SLOT
		box.corner_radius_top_right = UITokens.RADIUS_SLOT
		box.corner_radius_bottom_left = UITokens.RADIUS_SLOT
		box.corner_radius_bottom_right = UITokens.RADIUS_SLOT
		chip.add_theme_stylebox_override("panel", box)
		chip.visible = false
		row.add_child(chip)
		_creature_buff_chips.append(chip)

		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.custom_minimum_size = Vector2(BUFF_CHIP_SIZE, BUFF_CHIP_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
		chip.add_child(label)
		_creature_buff_chip_labels.append(label)

	_creature_buff_overflow_label = Label.new()
	_creature_buff_overflow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_buff_overflow_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_creature_buff_overflow_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_creature_buff_overflow_label.visible = false
	row.add_child(_creature_buff_overflow_label)


## Stat initial in the chip (A/D/H...), full detail in the tooltip -- the same
## "letter now, detail on inspection" split `_update_buff_row()` uses for food
## buffs, which this HUD had no equivalent of for a creature's own tonics.
func _update_creature_buff_row(creature: RefCounted) -> void:
	var buffs: Array = creature.get("active_buffs")
	var count := buffs.size()
	for i in _max_buff_chips:
		var show := i < count
		_creature_buff_chips[i].visible = show
		if not show:
			continue
		var buff: Dictionary = buffs[i]
		var stat := str(buff.get("stat", ""))
		_creature_buff_chip_labels[i].text = stat.substr(0, 1).to_upper() if stat.length() > 0 else "?"
		_creature_buff_chips[i].tooltip_text = "%s %+.0f%% -- %ds left" % [
			stat.capitalize(), (float(buff.get("scale", 0.0)) - 1.0) * 100.0,
			int(ceil(float(buff.get("remaining_s", 0.0)))),
		]
	var overflow := count - _max_buff_chips
	_creature_buff_overflow_label.visible = overflow > 0
	if overflow > 0:
		_creature_buff_overflow_label.text = "+%d" % overflow


func _update_creature_block() -> void:
	var creature: RefCounted = null
	if _party != null and int(_party.call("size")) > 0:
		creature = _party.call("active")
	var has_creature := creature != null

	if has_creature != _creature_block_has_creature_last:
		_creature_content.visible = has_creature
		_creature_no_creature_label.visible = not has_creature
		_creature_block_has_creature_last = has_creature

	_update_creature_header(has_creature)
	_update_party_pips()

	if not has_creature:
		return

	var species_id := str(creature.get("species_id"))
	_creature_chip.color = _species_tint(species_id)
	var portrait_path := _species_portrait_path(species_id)
	if portrait_path != _creature_portrait_path:
		_creature_portrait_path = portrait_path
		var portrait_texture: Texture2D = null
		if ResourceLoader.exists(portrait_path):
			portrait_texture = load(portrait_path) as Texture2D
		_creature_portrait.texture = portrait_texture
	_creature_name_label.text = str(creature.call("label"))
	_creature_level_label.text = "Lv %d" % int(creature.get("level"))
	if _creature_xp_label != null:
		var progression_cfg: Dictionary = CREATURE_PROGRESSION_HUD.config()
		var cap := int(progression_cfg.get("level", {}).get("cap", 50))
		if int(creature.get("level")) >= cap:
			_creature_xp_label.text = "max"
			_creature_xp_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		else:
			var near := PROGRESSION_FEED.xp_near(creature, progression_cfg)
			_creature_xp_label.text = "%d to Lv %d" % [
				PROGRESSION_FEED.xp_remaining(creature, progression_cfg), int(creature.get("level")) + 1
			]
			_creature_xp_label.add_theme_color_override("font_color",
				UITokens.WARNING if near else UITokens.TEXT_MUTED)

	var creature_type := str(creature.get("creature_type"))
	_creature_type_label.text = creature_type.to_upper()
	_creature_type_label.add_theme_color_override("font_color", _type_colour(creature_type))

	_creature_hp_bar.value = clampf(float(creature.call("hp_fraction")), 0.0, 1.0)
	_creature_hp_value_label.text = "%d / %d" % [
		int(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp")))),
	]

	var energy := float(creature.get("energy"))
	_creature_energy_bar.visible = energy > 0.0
	if _creature_energy_bar.visible:
		_creature_energy_bar.value = clampf(float(creature.call("energy_fraction")), 0.0, 1.0)

	_update_creature_buff_row(creature)


## Two independent critics both flagged the same contradiction: this block
## said "ACTIVE COMPANION <name>" while the centre prompt, at the same
## moment, offered "Call out <name>" -- i.e. the HUD asserted the creature
## was both out and stowed within ~100 vertical pixels. Investigation: it is
## a LABELLING bug, not a state bug. `Party.active()` (what this block reads)
## means "the roster slot the player has selected," full stop -- it carries
## no idea whether that creature is actually spawned in the world.
## `encounter_director.gd::_creature_control_offer()` is the thing that
## actually knows that, via its own `_ally_body` (a real `Node3D`, present
## only after `summon_active_creature()` runs) -- exposed publicly as
## `ally_body()`, and already read the same defensive way
## `_update_minimap()`'s own header describes (find "AllyCreature" by name in
## the current scene, no coupling to which provider is arbitrating). When
## no such node exists, the header now says "READY TO CALL OUT" instead of
## "ACTIVE COMPANION" -- true in both states, and never contradicts the
## centre prompt sitting right below it.
## HUD-POPUP: factored out of `_update_creature_header()` (the only caller
## before this task) so `_update_party_pips()` and `_update_party_strip()`
## below can ask the same question -- see their own callers for why. Still
## the one real source of truth this file has for "is the selected creature
## actually standing in the world," unchanged from the header's own long
## comment.
func _active_creature_is_out(has_creature: bool) -> bool:
	if not has_creature:
		return false
	var world := get_tree().get_current_scene()
	var ally: Node = world.get_node_or_null(^"AllyCreature") if world != null else null
	return ally != null and is_instance_valid(ally)


func _update_creature_header(has_creature: bool) -> void:
	var out := _active_creature_is_out(has_creature)
	if out == _creature_header_out_last and has_creature == _creature_header_has_creature_last:
		return
	_creature_header_out_last = out
	_creature_header_has_creature_last = has_creature
	_creature_header.text = "ACTIVE COMPANION" if out else "READY TO CALL OUT"


## Persistent five-pip roster readout -- filled+tinted for an owned slot,
## bright ring for whichever is active, dim red for fainted. See `_party_pips`'s
## declaration for why this exists alongside `party_strip.gd`'s own transient
## reveal rather than replacing it.
##
## HUD-POPUP task 2: a blind critic flagged two separate things about this
## row -- the pips themselves (~13 authored px, ~2px ring) reading as a
## squint at arm's length with no colour-to-creature legend anywhere, and a
## sharper conceptual gap: the party list's teal "active" highlight moves to
## a newly-selected creature at the exact moment the header above it says
## that creature is only "ready to be called out," so selected-but-not-out
## and actually-out-in-the-world shared one visual treatment. `PARTY_PIP_SIZE`
## answers the first (18 -> 28, matching `BUFF_CHIP_SIZE`'s own footprint,
## thicker ring). The second is answered here rather than invented new
## chrome: `_active_creature_is_out()` is the one place this file already
## knows the difference, so a selected-but-stowed pip gets the same
## `TEAL_SOFT` ring it always did (a pick, not a presence), while a selected
## AND summoned pip gets the brighter `TEAL` ring `party_strip.gd`'s own rail
## uses for the same state -- one colour now means one thing everywhere on
## this HUD, not "selected" doing double duty for two different facts.
func _update_party_pips() -> void:
	if _party == null:
		for i in _party_pip_boxes.size():
			_party_pip_boxes[i].bg_color = Color(UITokens.TEXT_MUTED, 0.35)
			_party_pip_boxes[i].border_color = UITokens.BORDER
			_party_pip_boxes[i].border_width_left = 1
			_party_pip_boxes[i].border_width_top = 1
			_party_pip_boxes[i].border_width_right = 1
			_party_pip_boxes[i].border_width_bottom = 1
		return
	var members: Array = _party.call("members")
	var active_index := int(_party.call("active_index"))
	var active_out := _active_creature_is_out(active_index >= 0 and active_index < members.size())
	for i in _party_pip_boxes.size():
		var box := _party_pip_boxes[i]
		var selected := i == active_index and i < members.size()
		var border_width := 4 if selected else 1
		box.border_width_left = border_width
		box.border_width_top = border_width
		box.border_width_right = border_width
		box.border_width_bottom = border_width
		if i >= members.size():
			box.bg_color = Color(UITokens.TEXT_MUTED, 0.18)
			box.border_color = UITokens.BORDER
			continue
		var member: RefCounted = members[i]
		var fainted := bool(member.get("fainted"))
		# GATE3-HUD-HIERARCHY (Gate 2 evidence judge, `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`
		# §6, and the shared oxblood-reservation finding it names alongside
		# G3-BAND1-FINISH's world half: "the board's reserved Team Tether
		# oxblood has leaked onto friendly HUD icons"). `DANGER` reads as an
		# active, urgent alert everywhere else it is used on this HUD (the
		# health bar sliding toward it, the fight-lost outcome text) -- a
		# fainted party member is not that, it is a PAST-TENSE unavailable
		# state, the same fact an empty roster slot two lines above signals
		# with a muted, low-alpha fill rather than a saturated colour. Reusing
		# that same "unavailable" language here is both more accurate (fainted
		# isn't an ongoing danger) and stops a friendly pip from carrying the
		# one hue this HUD is supposed to leave for Team Tether alone.
		box.bg_color = Color(UITokens.TEXT_MUTED, 0.55) if fainted else _distinct_tint(members, i)
		if not selected:
			box.border_color = UITokens.BORDER
		else:
			box.border_color = UITokens.TEAL if active_out else UITokens.TEAL_SOFT


func _species_tint(species_id: String) -> Color:
	if species_id.is_empty():
		return UITokens.TEXT_MUTED
	var placeholder: Dictionary = CREATURE_SPECIES.placeholder(species_id)
	return Color(str(placeholder.get("colour", "#cccccc")))


## A blind critic found two of the five party pips reading as the same
## colour ("both brown") -- `CreatureSpecies.placeholder()` hands out one
## fixed colour per species (data this lane does not own, see the file
## ownership list), and nothing stopped two of a five-creature roster from
## rolling the same placeholder tint. Rather than touch creature data, this
## nudges the hue of any tint that repeats EARLIER in the same roster list,
## by a fixed step per repeat -- deterministic (same roster always renders
## the same way), and shared by both `_update_party_pips()` and
## `_update_party_strip()`'s entries below, so a duplicate is resolved once
## and both widgets agree, the same "never tint the same creature two
## different colours" guarantee `_species_tint()`'s own callers already
## relied on for a SINGLE creature.
func _distinct_tint(members: Array, index: int) -> Color:
	var base := _species_tint(str((members[index] as RefCounted).get("species_id")))
	var earlier_matches := 0
	for j in index:
		if _species_tint(str((members[j] as RefCounted).get("species_id"))).is_equal_approx(base):
			earlier_matches += 1
	if earlier_matches == 0:
		return base
	var hue := fposmod(base.h + 0.16 * earlier_matches, 1.0)
	return Color.from_hsv(hue, clampf(base.s, 0.4, 1.0), clampf(base.v, 0.45, 1.0), base.a)


## Meadows ships a curated runtime copy of the owner-supplied render for every
## installed creature. Reusing it here gives the field HUD real species
## identity without adding portrait art or coupling the strip to 3D spawning.
## T3-CREATURES landed four ASPECT VARIANTS -- nightburrow, stormtrail,
## riftfrill, ashtusk -- which carry a `variant_of` and deliberately reuse their
## base species' `.glb` (a test now fails if a variant acquires a mesh of its
## own). They have no portrait of their own for the same reason, so this
## resolved four paths that do not exist and both portrait sites fell back to a
## bare colour swatch.
##
## An aspect variant falls back to its BASE species' portrait, which is the
## identical rule the mesh already follows: a Nightburrow IS a re-materialed
## Burrowback, so a Burrowback portrait is a true picture of it rather than a
## stand-in. Resolved rather than duplicated on disk, so landing a real portrait
## later is dropping in one file with no code change.
func _species_portrait_path(species_id: String) -> String:
	if species_id.is_empty():
		return ""
	var path := "res://assets/ui/portraits/creatures/%s.png" % species_id
	if ResourceLoader.exists(path):
		return path
	var base := str(CREATURE_SPECIES.definition(species_id).get("variant_of", ""))
	if base != "":
		return "res://assets/ui/portraits/creatures/%s.png" % base
	return path


## T3-MATCHUPS: the five expansion types (fire, electric, ice, psychic, dark)
## previously fell through to TEXT_SECONDARY here and to GROUND_OCHRE on the
## fight HUD -- two hand-written `match` statements that had already drifted
## apart on the fallback alone. Both now read one table in `ui_tokens.gd`.
##
## TEXT_SECONDARY stays the fallback here, and the difference from the fight
## HUD's is deliberate rather than leftover: out in the field an unrecognised
## type should recede into ordinary label text, while mid-fight the tag has to
## stay readable on the enemy plate.
func _type_colour(creature_type: String) -> Color:
	return UITokens.type_colour(creature_type, UITokens.TEXT_SECONDARY)


# --- party strip -----------------------------------------------------------------


## `party_strip.gd` never reaches `Game` itself (see its own header) — this is
## the one place that reads `Game.party` and hands it entries as plain data.
func _mount_party_strip() -> void:
	var script: Script = load(PARTY_STRIP_SCRIPT)
	if script == null:
		push_warning("HUD: party_strip.gd failed to load")
		return
	var inst: Variant = script.new()
	if not (inst is Control):
		push_warning("HUD: party_strip.gd did not produce a Control")
		return
	_party_strip = inst
	_party_strip_script = script
	_party_strip.name = "PartyStrip"
	_party_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Real position comes from `_reflow_left_stack()`, once the creature
	# panel below it has a real measured height -- see that function's
	# header. `party_strip.gd::set_rest_position()` is what actually places
	# it (and is safe to call before the widget has ever been shown, which
	# is exactly when this first runs).
	_root.add_child(_party_strip)


## Pure position math for the left column (party strip / creature panel /
## vitals cluster), stacked bottom-up above `Root/BottomDock`'s real top
## edge -- see `BOTTOM_DOCK_TOP_OFFSET`'s header comment for why this has to
## be derived from the CANVAS BOTTOM rather than a fixed top offset. Static
## and side-effect-free on purpose: `_reflow_left_stack()` is the only
## caller in real play, but `tests/test_hud_widgets.gd` exercises the same
## math with hand-picked canvas heights, with no scene tree required.
static func left_stack_bottom(canvas_height: float) -> float:
	return canvas_height + BOTTOM_DOCK_TOP_OFFSET - LEFT_STACK_CLEARANCE


## OWNER-HUD-INPUT-0903 (owner playtest 2026-09-03, item 8: "the food bar and
## health bar need to be stacked not next to each other"). The satiety plate
## is the LOWER of the two -- anchored directly off the true canvas bottom
## (`BOTTOM_VITALS_MARGIN`) -- with `player_health_bar_position()` deriving
## its own position from THIS plate's real top instead of a second
## independent canvas-bottom margin, so the two can never drift apart or
## overlap regardless of either row's height. See `VITALS_STACK_GAP`'s own
## header for why stacking here no longer reopens OWNER-0902-HUD-TEAM-MENU's
## "team menu overruns the food bar" defect.
static func vitals_position(canvas_height: float) -> Vector2:
	var margin := maxf(BOTTOM_VITALS_MARGIN, canvas_height * SAFE_AREA_BOTTOM_FRACTION)
	var plate_bottom := canvas_height - margin
	var plate_top := plate_bottom - (VITALS_HEIGHT_WITHOUT_HP + VITALS_PLATE_OVERHANG * 2.0)
	return Vector2(CREATURE_BLOCK_X, plate_top + VITALS_PLATE_OVERHANG)


## HUD-BACKLOG-20, restacked by OWNER-HUD-INPUT-0903 (see `vitals_position()`'s
## own header). The health plate sits directly ABOVE the satiety plate,
## sharing its X (`CREATURE_BLOCK_X`) and width (`VITALS_WIDTH`) so "health
## above food" reads as one column with a matching left edge, not two
## independently placed widgets that happen to line up. Deriving the gap from
## the food plate's REAL top (rather than a second hand-measured canvas-bottom
## margin) is what makes that true regardless of either plate's own height.
static func player_health_bar_position(canvas_height: float) -> Vector2:
	var food_pos: Vector2 = vitals_position(canvas_height)
	var food_plate_top := food_pos.y - VITALS_PLATE_OVERHANG
	var plate_bottom := food_plate_top - VITALS_STACK_GAP
	var plate_top := plate_bottom - (HEALTH_BAR_CONTENT_HEIGHT + VITALS_PLATE_OVERHANG * 2.0)
	return Vector2(CREATURE_BLOCK_X, plate_top + VITALS_PLATE_OVERHANG)


## OWNER-0902-HUD-TEAM-MENU: used to bottom out against `vitals_position()`,
## back when satiety shared this column with the roster. Now that satiety has
## moved down to sit with the health bar (see that function's own header),
## the active-creature panel has nothing left to clear in this column except
## `Root/BottomDock` itself, so it bottoms out directly against
## `left_stack_bottom()` -- the same edge the roster strip below now also
## measures from.
static func creature_block_position(canvas_height: float, creature_panel_height: float) -> Vector2:
	return Vector2(
		CREATURE_BLOCK_X,
		left_stack_bottom(canvas_height) - creature_panel_height,
	)


## GF-B-006 / `HIST-136` (OP23-09, owner: "the HUD takes up far too much
## screen"). The strip rests in the LEFT COLUMN, bottom-aligned a gap above the
## player vitals cluster.
##
## It used to rest to the RIGHT of the creature panel, in "its own screen
## region" -- the HUD-POPUP fix whose reasoning is kept below, because it solved
## a real compositing defect and its solution is still half of this one. What it
## could not know is where that region lands: at the authored 1920 canvas the
## panel's real width is 435, so the strip started at x 505 and ran to 755, and
## the central third begins at 640. Gate F photographed the result -- `TEAM 0/5`
## and five `OPEN SLOT` rows stacked over the middle of the viewport, directly
## over the ground the player is walking into. It also crosses the full-height
## 440px trainer/camera focus lane that `smoke_prompt_hotbar_dock.gd` already
## forbids the hotbar from touching.
##
## There is no third place. Measured at the authored canvas: the creature panel
## occupies x 56-491, the minimap and objective block own the right column down
## to y 480, and the bottom dock starts at 620. Anything placed right of the
## creature panel and wide enough to hold a species name at this HUD's own
## legibility floor is inside the central third by construction. So the strip
## comes back to the left column, and the two changes that let it fit are:
##
## 1. `party_strip.gd` lays each row on ONE text line rather than two, so
##    `TOTAL_HEIGHT` is 350 rather than 540;
## 2. the creature panel STANDS DOWN while the strip is revealed
##    (`_yield_creature_block_to_party_strip()`), because the strip is a
##    superset of it -- the panel names the active creature, and the strip names
##    the active creature with its four team-mates around it, which is the whole
##    point of a roster reveal.
##
## That second change is what makes the original HUD-POPUP defect impossible
## rather than merely avoided. Disjoint rects still both draw; two widgets that
## are never on screen together cannot composite through each other at all.
##
## OWNER-0902-HUD-TEAM-MENU: the bottom bound used to be the vitals cluster
## (HP/satiety shared this column back then), which is exactly how a tall
## reveal ran into the food bar sitting underneath it (owner playtest
## 2026-09-02, finding #11). `vitals_position()` has since moved satiety down
## to sit with the health bar, out of this column entirely -- so the strip's
## real floor is `Root/BottomDock`'s own top edge (`left_stack_bottom()`),
## the same fixture the creature panel it stands in for already bottoms out
## against.
##
## --- the HUD-POPUP reasoning this replaces, kept because it is still why the
## --- strip may not simply be drawn over the creature panel:
##
## the party strip used to hug the creature panel from directly above
## (`party_strip_position()`'s old header spelled out the tradeoff: its own
## `TOTAL_HEIGHT`, 540, never fit in the room actually left above a
## correctly bottom-anchored creature panel at either supported canvas
## height, so the clamp let the reveal draw its bottom rows straight over
## the panel behind it). A blind critic then confirmed exactly that frame --
## the panel's own title compositing through a party row's name, its HP
## readout floating over the row beneath it, six distinct collisions from
## one shared rect. Of the critic's three fixes (opaque the popup, move it
## off the list, or hide the list while the popup is open), that pass took
## "move it off the list". Chosen over "hide the list": OP21-12's whole point
## was showing the roster DURING a cycle, not replacing it with the
## single-creature panel at the exact moment the player most wants to see
## where the new active creature sits among all five. This pass does the
## inverse of that rejected option -- it hides the SINGLE-CREATURE PANEL
## while the ROSTER is up, which keeps OP21-12's requirement intact.
static func party_strip_position(canvas_height: float, strip_height: float) -> Vector2:
	# Bottom-aligned against `Root/BottomDock`'s real top edge rather than
	# top-anchored at `TOP_SAFE_INSET`: that dock is the fixture the strip
	# must clear, and deriving from it means a change to the strip's own row
	# height can never silently push the two into each other.
	var bottom: float = left_stack_bottom(canvas_height)
	# ...but never above the top safe inset, which is where the reveal lines up
	# with the minimap and objective block's own top row.
	return Vector2(CREATURE_BLOCK_X, maxf(TOP_SAFE_INSET, bottom - strip_height))


## Pure text formatting for the day/time readout, split out so
## `tests/test_hud_widgets.gd` can pin the format without instancing the HUD
## or a live `WorldLook` clock. `hour` is `day_cycle.gd::hour_at()`'s own
## 0..24 float; `@ 24:00` never happens because `fposmod` in that function
## always wraps it back under 24 first, but this still floors/wraps
## defensively so a caller passing a raw, un-wrapped value (a test, a future
## refactor) reads as a clock and not as garbage.
static func daytime_readout_text(day: int, hour: float) -> String:
	var wrapped := fposmod(hour, 24.0)
	var h := int(wrapped)
	var m := int(round((wrapped - float(h)) * 60.0)) % 60
	return "Day %d  ·  %02d:%02d" % [maxi(day, 1), h, m]


## Places the whole left column from the CANVAS BOTTOM every time `_root`'s
## actual size is seen to change (once at startup, since `_ready()` can run
## before the viewport has settled its final stretch size, and again only if
## a real resize ever happens -- never mid-session in practice). Cheap and
## rare rather than run unconditionally every frame specifically so it never
## fights `party_strip.gd`'s own reveal/hide tween, which owns `.position`
## the rest of the time.
func _reflow_left_stack() -> void:
	var canvas_h: float = _root.size.y
	if canvas_h <= 0.0:
		return
	# The creature panel's real height can itself change (the energy bar row
	# joining/leaving, a longer name wrapping) -- gating this whole function
	# on canvas height alone would leave the party strip's REST position
	# stale the next time it revealed. `vitals_cluster`/`creature_block`
	# never animate their own `.position`, so repositioning them every frame
	# is just a couple of cheap Vector2 writes; only the party strip's tween
	# needs the change-guard below.
	# A `PanelContainer` parented directly under a plain `Control` (as this
	# one is, under `_creature_block`) does not automatically grow its own
	# `.size` to match its children's real minimum size the way it would
	# inside a parent Container -- that auto-fit only happens one layer up.
	# Setting it explicitly here, every time this runs, is what makes the
	# panel's OWN rect (what `get_global_rect()` reports, and what the
	# bounds tests in `tests/smoke_hud_handheld_legibility.gd` check every
	# child against) actually match its content instead of staying frozen at
	# whatever `custom_minimum_size` floor it started with.
	var creature_h := 0.0
	var creature_w := CREATURE_BLOCK_MIN_WIDTH
	if _creature_panel != null:
		var min_size := _creature_panel.get_combined_minimum_size()
		_creature_panel.size = min_size
		creature_h = min_size.y
		creature_w = min_size.x

	if _vitals_cluster != null:
		_vitals_cluster.position = vitals_position(canvas_h)

	if _health_bar_cluster != null:
		_health_bar_cluster.position = player_health_bar_position(canvas_h)

	if _creature_block != null:
		_creature_block.position = creature_block_position(canvas_h, creature_h)

	# HUD-POPUP: the party strip's rest X now tracks the creature panel's
	# real WIDTH too (see `party_strip_position()`'s own header for why a
	# fixed guess at that width was not enough), so the change-guard has to
	# watch it alongside canvas height -- a creature swap that changes the
	# panel's content width (a longer name, the type tag, the HP value
	# column) has to re-place the strip even when the canvas itself did not
	# resize.
	if is_equal_approx(canvas_h, _left_stack_canvas_h) and is_equal_approx(creature_w, _left_stack_creature_w):
		return
	_left_stack_canvas_h = canvas_h
	_left_stack_creature_h = creature_h
	_left_stack_creature_w = creature_w

	if _party_strip != null and _party_strip_script != null:
		var strip_h: float = float(_party_strip_script.get("TOTAL_HEIGHT"))
		var strip_pos := party_strip_position(canvas_h, strip_h)
		if _party_strip.has_method("set_rest_position"):
			_party_strip.call("set_rest_position", strip_pos)
		else:
			_party_strip.position = strip_pos


## Wired to `Game.party.active_index()` + `.revision`: rebuild entries and
## reveal the strip only when either actually changed, per the task spec --
## polling every frame but writing only on a real change, the same discipline
## the widget's own per-row cache already uses internally.
##
## OP21-12: also decides whether this change was a genuine cycle (the active
## index landed on the slot immediately before/after where it just was, with
## wrap) and if so hands the widget a `flash_cycle()` call — this is the one
## place both the old and new index are known, since `encounter_director.gd`
## (which actually reads `party_cycle`) only ever sees the new
## state through `Party.revision`.
func _update_party_strip() -> void:
	if _party_strip == null or _party == null:
		return
	var index := int(_party.call("active_index"))
	var revision := int(_party.get("revision"))
	# HUD-POPUP: `active_out` (whether the selected creature is actually
	# standing in the world, not just picked) can flip on its own -- calling
	# out or recalling a creature touches neither `active_index` nor
	# `Party.revision` -- so the early-out below has to watch it too, or the
	# rail/pip's "picked vs present" distinction goes stale exactly at the
	# moment a summon/recall makes it matter.
	var has_active_creature := index >= 0 and index < int(_party.call("size"))
	var active_out := _active_creature_is_out(has_active_creature)
	# PROGRESSION-VISIBLE: the feed's revision is a third change input. An xp
	# award or a bond credit moves neither `active_index` nor
	# `Party.revision`, and the strip's xp sliver / bond pip are read off the
	# entries built below -- so without this they would sit stale until the
	# next catch or faint.
	var feed_revision := PROGRESSION_FEED.revision()
	if index == _party_strip_last_index and revision == _party_strip_last_revision \
			and active_out == _party_strip_last_active_out \
			and feed_revision == _party_strip_last_feed_revision:
		return
	var roster_changed := index != _party_strip_last_index or revision != _party_strip_last_revision \
			or active_out != _party_strip_last_active_out
	_party_strip_last_feed_revision = feed_revision
	_party_strip_last_active_out = active_out
	var previous_index := _party_strip_last_index
	var previous_label := _party_strip_last_active_label
	_party_strip_last_index = index
	_party_strip_last_revision = revision

	var members: Array = _party.call("members")
	var entries: Array = []
	var progression_cfg: Dictionary = CREATURE_PROGRESSION_HUD.config()
	for i in members.size():
		var creature: RefCounted = members[i]
		var entry := {
			"label": str(creature.call("label")),
			"level": int(creature.get("level")),
			"hp_fraction": float(creature.call("hp_fraction")),
			"tint": _distinct_tint(members, i),
			"portrait": _species_portrait_path(str(creature.get("species_id"))),
			"fainted": bool(creature.get("fainted")),
			"resting": bool(creature.get("resting")),
		}
		entry.merge(BOND_MILESTONES_HUD.strip_fields(creature, progression_cfg))
		entries.append(entry)
	_party_strip.call("update_from_party", entries, index, active_out)
	if not roster_changed:
		# A feed-only refresh: the rows are current, and the strip's own
		# `_poll_feed` decides whether the event was worth revealing for.
		return
	# GF-B-006: an EMPTY roster does not reveal.
	#
	# The reveal fires on any change to the party's index, revision or
	# called-out state -- including the very first poll after the HUD mounts,
	# when the change-guard above is comparing against its `-999` sentinel. With
	# no creatures caught yet that put `TEAM 0/5` and five `OPEN SLOT` rows on
	# screen at world load, which is the exact frame Gate F photographed
	# (`X07/frames/X07/000312.88.png`), and it is the state the player is in for
	# the whole opening: from the first step out of the village until the first
	# catch. There is nothing to reveal. A roster reveal exists to show where a
	# newly active creature sits among five; five empty slots answer a question
	# nobody asked and cover the ground the player is walking into to do it.
	#
	# `update_from_party` still ran above, so the rows are current the moment
	# the first catch gives the strip something to say -- and that catch is
	# itself a `revision` change, so it reveals then, which is the right moment.
	if not entries.is_empty():
		_party_strip.call("show_strip")

	var total := entries.size()
	var next_label := str(entries[index].get("label", "")) if index >= 0 and index < total else ""
	_party_strip_last_active_label = next_label

	if previous_index >= 0 and previous_index != index and total > 0 \
			and not previous_label.is_empty() and not next_label.is_empty():
		var direction := 0
		if (previous_index + 1) % total == index:
			direction = 1
		elif (previous_index - 1 + total) % total == index:
			direction = -1
		if direction != 0:
			_party_strip.call("flash_cycle", direction, previous_label, next_label, index + 1, total)


# --- player vitals cluster --------------------------------------------------------


## GATE3-HUD-CONTRAST (Gate 2 evidence judge, `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`
## §6: "the 100 / 100 health text is light green on a green bar"). Measured:
## the label's previously-unset default ~0.875-grey fill against `HP_GREEN`
## is a 1.6:1 WCAG contrast ratio at full health -- the exact frame the
## critic judged. No single text colour fixes this, because the bar this text
## sits on top of is not one colour: `HP_GREEN` sweeps to `DANGER` as HP
## drops, briefly flashes white on a hit, and -- since the value text is
## right-aligned over a LEFT-filling bar -- at low HP the text actually sits
## over the bar's unfilled TRACK (near-black) rather than its fill at all.
## Dark text reads well against the bright fill states and vanishes against
## the track; light text is the reverse. An opaque chip behind just the
## digits removes the dependency on the bar's state entirely: the text's
## contrast is against `OUTLINE`'s own colour (already used everywhere on
## this HUD to punch text out of the busy world behind it), never against
## the meter.
func _style_meter_value_chip() -> Panel:
	var chip := Panel.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UITokens.OUTLINE, 1.0)
	box.corner_radius_top_left = UITokens.RADIUS_BAR
	box.corner_radius_top_right = UITokens.RADIUS_BAR
	box.corner_radius_bottom_left = UITokens.RADIUS_BAR
	box.corner_radius_bottom_right = UITokens.RADIUS_BAR
	chip.add_theme_stylebox_override("panel", box)
	return chip


## Resizes `chip` to hug `label`'s current text and right-aligns it to
## `label`'s own right edge, so a `999 / 999` string gets the same guarantee
## a `7 / 40` one does instead of the chip being sized for a guessed worst
## case. Called every time the label's text changes.
func _fit_meter_value_chip(chip: Panel, label: Label) -> void:
	if chip == null or label == null:
		return
	var font: Font = label.get_theme_font("font")
	if font == null:
		font = ThemeDB.fallback_font
	var font_size := label.get_theme_font_size("font_size")
	var text_size: Vector2 = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	if text_size.x <= 0.0:
		chip.size = Vector2.ZERO
		return
	var pad_x := 10.0
	var pad_y := 4.0
	var width := text_size.x + pad_x * 2.0
	var height := text_size.y + pad_y * 2.0
	var right_edge := label.position.x + label.size.x
	chip.size = Vector2(width, height)
	chip.position = Vector2(right_edge - width, label.position.y + (label.size.y - height) * 0.5)


## Buff icons row, satiety row (bar + hunger-state text). One Control holds
## both so the idle-fade rule can fade the whole cluster with a single
## modulate write, matching the old per-bar fade this replaces.
##
## HUD-BACKLOG-20: the HP row used to live here too. It now builds in
## `_build_player_health_bar()`'s own widget instead -- see that function's
## header, and `VITALS_HEIGHT_WITHOUT_HP`'s, for why this cluster's own
## position formula (`vitals_position()`) is untouched even though its real
## content shrank.
func _build_vitals_cluster() -> void:
	_vitals_cluster = Control.new()
	_vitals_cluster.name = "VitalsCluster"
	_vitals_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Position is set by `_reflow_left_stack()`, not here -- see that
	# function's header and `BOTTOM_DOCK_TOP_OFFSET`'s comment for why a
	# fixed top-anchored offset was the actual HUD-LAYOUT defect.
	_vitals_cluster.size = Vector2(VITALS_WIDTH, VITALS_HEIGHT_WITHOUT_HP)
	_root.add_child(_vitals_cluster)

	# HUD-EMPHASIS: a blind critic named this corner the one that "reads
	# unfinished relative to the rest of the HUD" -- gold "FOOD" text on a
	# gold bar, numerals half-on half-off the bar fill, no containing panel
	# while every other cluster (creature block, roster, quest block, hotbar,
	# legend) wears one. The comment above on the HP icon's own backing chip
	# already documents the deliberate original call ("legibility outline
	# instead of a box") -- superseded here the same way `_build_objective_block()`'s
	# own header describes for the quest block: a small translucent panel,
	# not a new "giant window," sized to the cluster's own real content
	# (including the icon columns that sit at negative local x) rather than
	# growing to cover anything more.
	var vitals_plate := Panel.new()
	vitals_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals_plate.position = Vector2(-40.0, -VITALS_PLATE_OVERHANG)
	vitals_plate.size = Vector2(VITALS_WIDTH + 48.0, VITALS_HEIGHT_WITHOUT_HP + VITALS_PLATE_OVERHANG * 2.0)
	vitals_plate.add_theme_stylebox_override("panel", UITokens.panel_box())
	_vitals_cluster.add_child(vitals_plate)

	_build_buff_row(_vitals_cluster)

	# HUD-POPUP task 4: "the yellow satiety bar has no icon, label or value;
	# next to a heart-marked HP bar it is a mystery meter." No new icon
	# asset -- that needs an owner-supplied reference sheet this glyph does
	# not have (`conventions.md`) -- so a "FOOD" text caption stands in for
	# one, the same role the HP heart icon plays, followed by a real bar and
	# a right-aligned percentage value mirroring the HP row exactly.
	_satiety_caption_label = Label.new()
	_satiety_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_satiety_caption_label.position = Vector2(0.0, VITALS_FOOD_ONLY_ROW_Y - 8.0)
	_satiety_caption_label.size = Vector2(VITALS_CAPTION_WIDTH - 8.0, 34.0)
	_satiety_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_satiety_caption_label.text = "FOOD"
	_satiety_caption_label.add_theme_font_size_override("font_size", VITALS_VALUE_FONT)
	_satiety_caption_label.add_theme_color_override("font_color", UITokens.WARNING)
	_vitals_cluster.add_child(_satiety_caption_label)

	_satiety_bar = ProgressBar.new()
	_satiety_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_satiety_bar.position = Vector2(VITALS_CAPTION_WIDTH, VITALS_FOOD_ONLY_ROW_Y)
	_satiety_bar.size = Vector2(VITALS_WIDTH - VITALS_CAPTION_WIDTH, VITALS_BAR_HEIGHT)
	_satiety_bar.show_percentage = false
	_satiety_bar.min_value = 0.0
	_satiety_bar.max_value = 1.0
	_satiety_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_satiety_bar.add_theme_stylebox_override("fill", UITokens.fill_box(UITokens.WARNING))
	_vitals_cluster.add_child(_satiety_bar)

	# GATE3-HUD-CONTRAST: the chip is added FIRST so it draws behind the label
	# added right after it -- see `_style_meter_value_chip()`'s own header.
	_satiety_value_chip = _style_meter_value_chip()
	_vitals_cluster.add_child(_satiety_value_chip)

	_satiety_value_label = Label.new()
	_satiety_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_satiety_value_label.position = Vector2(VITALS_CAPTION_WIDTH, VITALS_FOOD_ONLY_ROW_Y - 8.0)
	_satiety_value_label.size = Vector2(VITALS_WIDTH - VITALS_CAPTION_WIDTH - 8.0, 34.0)
	_satiety_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_satiety_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_satiety_value_label.add_theme_font_size_override("font_size", VITALS_VALUE_FONT)
	_satiety_value_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_vitals_cluster.add_child(_satiety_value_label)

	# HUNGRY/STARVING tag: kept outside `VITALS_WIDTH` to the right, same as
	# before, so it never needs its own row (and never grows `VITALS_HEIGHT`,
	# which the left-stack reflow treats as fixed) -- only its font size
	# changes here, `FONT_TINY` (19, ~8.9 physical px) being well under this
	# task's own floor for a state word the player needs to actually read.
	_satiety_state_label = Label.new()
	_satiety_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_satiety_state_label.position = Vector2(VITALS_WIDTH + 12.0, VITALS_FOOD_ONLY_ROW_Y - 8.0)
	_satiety_state_label.size = Vector2(220.0, 34.0)
	_satiety_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_satiety_state_label.add_theme_font_size_override("font_size", VITALS_VALUE_FONT)
	_satiety_state_label.visible = false
	_vitals_cluster.add_child(_satiety_state_label)


## HUD-BACKLOG-20 (owner playtest 2026-08-30, item 20: "Put the player's
## health bar in the lower left"). Same icon/bar/value the old HP row inside
## `_vitals_cluster` drew (`hp_heart.png` backing chip and all -- see that
## code's own history for why the chip exists), just re-homed into its own
## `Control` so it can be positioned independently by
## `player_health_bar_position()` instead of being pinned to
## `vitals_position()`'s spot above `Root/BottomDock`.
func _build_player_health_bar() -> void:
	_health_bar_cluster = Control.new()
	_health_bar_cluster.name = "PlayerHealthBar"
	_health_bar_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Position is set by `_reflow_left_stack()`, not here -- matches
	# `_vitals_cluster`'s own convention.
	_health_bar_cluster.size = Vector2(VITALS_WIDTH, HEALTH_BAR_CONTENT_HEIGHT)
	_root.add_child(_health_bar_cluster)

	var health_plate := Panel.new()
	health_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_plate.position = Vector2(-40.0, -VITALS_PLATE_OVERHANG)
	health_plate.size = Vector2(VITALS_WIDTH + 48.0, HEALTH_BAR_CONTENT_HEIGHT + VITALS_PLATE_OVERHANG * 2.0)
	health_plate.add_theme_stylebox_override("panel", UITokens.panel_box())
	_health_bar_cluster.add_child(health_plate)

	# hp_heart.png is a mid-tone green glyph, matching HP_GREEN by design (see
	# ASSET_LEDGER.md). A small round BG_PANEL chip behind it keeps it
	# legible against grass/terrain -- same call `_build_vitals_cluster()`
	# made for this icon before the split.
	var hp_icon_bg := Panel.new()
	hp_icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_icon_bg.position = Vector2(-30.0, HEALTH_BAR_ROW_Y - 4.0)
	hp_icon_bg.size = Vector2(26.0, 26.0)
	var hp_icon_bg_box := StyleBoxFlat.new()
	hp_icon_bg_box.bg_color = UITokens.BG_PANEL
	hp_icon_bg_box.corner_radius_top_left = 13
	hp_icon_bg_box.corner_radius_top_right = 13
	hp_icon_bg_box.corner_radius_bottom_left = 13
	hp_icon_bg_box.corner_radius_bottom_right = 13
	hp_icon_bg.add_theme_stylebox_override("panel", hp_icon_bg_box)
	_health_bar_cluster.add_child(hp_icon_bg)

	_hp_icon = TextureRect.new()
	_hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_icon.texture = load(ICON_HP)
	_hp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hp_icon.position = Vector2(-26.0, HEALTH_BAR_ROW_Y)
	_hp_icon.size = Vector2(18.0, 18.0)
	_health_bar_cluster.add_child(_hp_icon)

	_hp_bar = ProgressBar.new()
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.position = Vector2(0.0, HEALTH_BAR_ROW_Y)
	_hp_bar.size = Vector2(VITALS_WIDTH, VITALS_BAR_HEIGHT)
	_hp_bar.show_percentage = false
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 1.0
	_hp_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_hp_fill = UITokens.fill_box(UITokens.HP_GREEN)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	_health_bar_cluster.add_child(_hp_bar)

	# GATE3-HUD-CONTRAST: the chip is added FIRST so it draws behind the label
	# added right after it -- see `_style_meter_value_chip()`'s own header.
	_hp_value_chip = _style_meter_value_chip()
	_health_bar_cluster.add_child(_hp_value_chip)

	_hp_value_label = Label.new()
	_hp_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_value_label.position = Vector2(0.0, HEALTH_BAR_ROW_Y - 8.0)
	_hp_value_label.size = Vector2(VITALS_WIDTH - 8.0, 34.0)
	_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_value_label.add_theme_font_size_override("font_size", VITALS_VALUE_FONT)
	_hp_value_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_health_bar_cluster.add_child(_hp_value_label)


## T3-INSTALL, B1 (`ralph/reports/DARK_FEATURES_INVENTORY_2026-08-30.md`):
## `vitals.json`'s `buffs` block had no reader anywhere in `scripts/ui/`.
## Wires it to both buff rows' chip count instead of deleting it -- the key
## already named a real, useful dial (how many stacked buffs the HUD shows
## before collapsing to "+N"), it was just never read.
func _load_buff_config() -> void:
	var file := FileAccess.open(VITALS_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("vitals.json missing at %s; buff row defaults to %d icons" % [
			VITALS_CONFIG_PATH, DEFAULT_MAX_BUFF_CHIPS])
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var buffs: Variant = (parsed as Dictionary).get("buffs", {})
	if buffs is Dictionary and (buffs as Dictionary).has("max_visible_icons"):
		_max_buff_chips = maxi(1, int((buffs as Dictionary)["max_visible_icons"]))


func _build_buff_row(parent: Control) -> void:
	var x := 0.0
	for i in _max_buff_chips:
		var chip := Panel.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.position = Vector2(x, 0.0)
		chip.size = Vector2(BUFF_CHIP_SIZE, BUFF_CHIP_SIZE)
		var box := StyleBoxFlat.new()
		box.bg_color = UITokens.SUCCESS
		box.corner_radius_top_left = UITokens.RADIUS_SLOT
		box.corner_radius_top_right = UITokens.RADIUS_SLOT
		box.corner_radius_bottom_left = UITokens.RADIUS_SLOT
		box.corner_radius_bottom_right = UITokens.RADIUS_SLOT
		chip.add_theme_stylebox_override("panel", box)
		chip.visible = false
		parent.add_child(chip)
		_buff_chips.append(chip)

		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size = Vector2(BUFF_CHIP_SIZE, BUFF_CHIP_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
		chip.add_child(label)
		_buff_chip_labels.append(label)

		x += BUFF_CHIP_SIZE + UITokens.GAP

	_buff_overflow_label = Label.new()
	_buff_overflow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buff_overflow_label.position = Vector2(x, 6.0)
	_buff_overflow_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_buff_overflow_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_buff_overflow_label.visible = false
	parent.add_child(_buff_overflow_label)


func _update_buff_row(vitals: RefCounted) -> void:
	var buffs: Array = vitals.active_buffs
	var count := buffs.size()
	for i in _max_buff_chips:
		var show := i < count
		_buff_chips[i].visible = show
		if show:
			var buff: Dictionary = buffs[i]
			var id := str(buff.get("id", ""))
			_buff_chip_labels[i].text = id.substr(0, 1).to_upper() if id.length() > 0 else "?"
	var overflow := count - _max_buff_chips
	_buff_overflow_label.visible = overflow > 0
	if overflow > 0:
		_buff_overflow_label.text = "+%d" % overflow


## HP: bar + "284 / 320" value text, a brief white-ish flash on any decrease
## (`T_DAMAGE_FLASH`), and below `HP_DANGER_BELOW` a lerp toward `DANGER` plus
## a gentle alpha pulse on the bar itself (not the whole cluster -- the pulse
## should read as "this bar is alarmed", not affect the buff row above it).
## Satiety: bar + hunger-state text ("HUNGRY" / "STARVING"). Then the whole
## cluster's idle-fade, unchanged in spirit from the old per-bar version.
func _update_vitals_cluster(vitals: RefCounted, delta: float) -> void:
	var health_fraction: float = vitals.health_fraction()
	var health_value: float = vitals.health
	var max_health: float = vitals.max_health

	if _last_health_value >= 0.0 and health_value < _last_health_value - 0.001:
		_health_flash_timer = UITokens.T_DAMAGE_FLASH
	_last_health_value = health_value

	_hp_bar.value = health_fraction
	var normal_colour := UITokens.HP_GREEN.lerp(UITokens.DANGER, 1.0 - health_fraction)
	if _health_flash_timer > 0.0:
		_health_flash_timer = maxf(0.0, _health_flash_timer - delta)
		var t: float = _health_flash_timer / UITokens.T_DAMAGE_FLASH
		_hp_fill.bg_color = Color(1.0, 1.0, 1.0).lerp(normal_colour, 1.0 - t)
	else:
		_hp_fill.bg_color = normal_colour

	if health_fraction < HP_DANGER_BELOW:
		_hp_pulse_time += delta
		_hp_bar.modulate.a = 1.0 - HP_PULSE_DEPTH * absf(sin(_hp_pulse_time * HP_PULSE_SPEED))
	else:
		_hp_pulse_time = 0.0
		_hp_bar.modulate.a = 1.0

	_hp_value_label.text = "%d / %d" % [int(round(health_value)), int(round(max_health))]
	_fit_meter_value_chip(_hp_value_chip, _hp_value_label)

	var satiety_fraction: float = vitals.satiety_fraction()
	_satiety_bar.value = satiety_fraction
	_satiety_value_label.text = "%d%%" % int(round(satiety_fraction * 100.0))
	_fit_meter_value_chip(_satiety_value_chip, _satiety_value_label)
	var hunger := str(vitals.call("hunger_state"))
	match hunger:
		"hungry":
			_satiety_state_label.text = "HUNGRY"
			_satiety_state_label.add_theme_color_override("font_color", UITokens.WARNING)
			_satiety_state_label.visible = true
		"critical":
			_satiety_state_label.text = "STARVING"
			_satiety_state_label.add_theme_color_override("font_color", UITokens.DANGER)
			_satiety_state_label.visible = true
		_:
			_satiety_state_label.visible = false

	_update_buff_row(vitals)

	var sprinting: bool = bool(_player.call("is_sprinting")) if _player.has_method("is_sprinting") else false
	var relevant := health_fraction < 0.999 or hunger != "ok" or sprinting
	_fade_toward(_vitals_cluster, 1.0 if relevant else FADE_ALPHA, delta)
	# HUD-BACKLOG-20: same idle-fade rule, retargeted -- the split moved the
	# HP row out of `_vitals_cluster`, not out of the "safety information
	# never fully fades" contract `relevant` encodes.
	_fade_toward(_health_bar_cluster, 1.0 if relevant else FADE_ALPHA, delta)


# --- stamina arc -------------------------------------------------------------------


func _mount_stamina_arc() -> void:
	var script: Script = load(STAMINA_ARC_SCRIPT)
	if script == null:
		push_warning("HUD: stamina_arc.gd failed to load")
		return
	var inst: Variant = script.new()
	if not (inst is Control):
		push_warning("HUD: stamina_arc.gd did not produce a Control")
		return
	_stamina_arc = inst
	_stamina_arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_arc.position = STAMINA_ARC_POS
	_root.add_child(_stamina_arc)

	# Centred above the arc's own SIZE (48x160, stamina_arc.gd), so it reads
	# as the gauge's label rather than a stray badge. Fades with the arc
	# itself in _update_stamina_arc below -- the icon has nothing to say
	# once the gauge has hidden.
	# 24x24, not 18x18 -- blind-judge finding (EV9 handheld-scale remainder,
	# round 2): the bolt's zigzag notch, the one feature that reads as
	# "lightning" rather than a generic blob, softens into a rounded paddle
	# shape at 18px/315ppi. Same lever EV9's second slice already used for
	# an input-glyph legibility miss (28px->36px). Position offset shifted
	# by -half the size delta so the icon stays centred on the same anchor
	# point above the arc.
	_stamina_icon = TextureRect.new()
	_stamina_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_icon.texture = load(ICON_STAMINA)
	_stamina_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stamina_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stamina_icon.position = STAMINA_ARC_POS + Vector2(12.0, -27.0)
	_stamina_icon.size = Vector2(24.0, 24.0)
	_stamina_icon.visible = false
	_stamina_icon.modulate.a = 0.0
	_root.add_child(_stamina_icon)


func _update_stamina_arc(vitals: RefCounted, delta: float) -> void:
	if _stamina_arc == null:
		return
	var fraction: float = vitals.stamina_fraction()
	var sprinting: bool = bool(_player.call("is_sprinting")) if _player.has_method("is_sprinting") else false
	var draining := sprinting or (_last_stamina_fraction >= 0.0 and fraction < _last_stamina_fraction - 0.0001)
	_stamina_arc.call("update_stamina", fraction, draining, delta)
	_last_stamina_fraction = fraction

	if _stamina_icon != null:
		_stamina_icon.visible = _stamina_arc.visible
		_stamina_icon.modulate.a = _stamina_arc.modulate.a


# --- minimap (mounted defensively; owned by a concurrent pass) ---------------------


func _mount_minimap() -> void:
	if not ResourceLoader.exists(MINIMAP_SCRIPT):
		push_warning("HUD: minimap.gd not found; minimap disabled for this pass")
		return
	var script: Script = load(MINIMAP_SCRIPT)
	if script == null:
		push_warning("HUD: minimap.gd failed to load; minimap disabled")
		return
	var inst: Variant = script.new()
	if not (inst is Control):
		push_warning("HUD: minimap.gd did not produce a Control; minimap disabled")
		return
	_minimap = inst
	_minimap.name = "Minimap"
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap.position = Vector2(
		1920.0 - UITokens.HUD_INSET - MINIMAP_SIZE.x, UITokens.HUD_INSET
	)
	# HUD-SCALE: `MINIMAP_SIZE` used to feed the POSITION only -- `minimap.gd`
	# carries its own 240x240 `custom_minimum_size` and won, so cutting the
	# constant moved the widget without resizing it (caught by
	# `tools/_measure_hud_footprint.gd` still reporting 240x240 after the cut).
	# Sized here rather than in `minimap.gd` so that widget keeps its own
	# default for anything that mounts it outside this HUD.
	_minimap.custom_minimum_size = MINIMAP_SIZE
	_root.add_child(_minimap)
	# AFTER `add_child`, and that ordering is load-bearing: assigning `size` on
	# the line above left the widget at 240x240 with a 184x184 combined
	# minimum, because `Control.set_size()` clamps against a minimum-size cache
	# that `minimap.gd::_init()`'s own 240 had populated and the assignment two
	# lines earlier had not yet invalidated. Measured, not guessed --
	# `tools/_measure_hud_footprint.gd` kept reporting a 240x240 minimap after
	# `MINIMAP_SIZE` was already 184 and the widget's POSITION had moved.
	_minimap.size = MINIMAP_SIZE


## Baked lazily and once: `map_baker.gd::bake_cached` is a real terrain bake
## the first time it runs (cheap after, via its own disk cache), so this waits
## for a world with `ground_height_at` to exist rather than baking in
## `_ready()` before the world scene is necessarily up -- headless-safe, same
## reasoning `tools/capture_minimap.gd` already relies on.
func _ensure_minimap_baked() -> void:
	if _minimap == null or _minimap_baked:
		return
	var world := get_tree().get_current_scene()
	if world == null or not world.has_method("ground_height_at"):
		return
	if not ResourceLoader.exists(MAP_BAKER_SCRIPT):
		return
	var baker: Script = load(MAP_BAKER_SCRIPT)
	if baker == null:
		return
	if _game == null:
		return
	var game_map: RefCounted = _game.get("map")
	if game_map == null:
		return
	var terrain: Texture2D = baker.call("bake_cached", world)
	_minimap.call("configure", game_map, terrain, 90.0)
	_minimap_baked = true


## `player.global_position` and LOOK yaw derived from `CameraRig.planar_basis()`
## rather than read off a private field. `minimap.gd` derives its separate
## travel heading from successive real positions after movement resolution.
## Both use the project convention `forward(yaw) = (sin(yaw), 0, cos(yaw))`.
## `creature_pos` is the follower creature's
## position when `encounter_director.gd` has spawned one (named "AllyCreature" in
## the world, per that file), else null.
func _update_minimap() -> void:
	if _minimap == null or not _minimap_baked or _player == null:
		return
	var world := get_tree().get_current_scene()
	var yaw := 0.0
	if world != null:
		var rig := world.get_node_or_null(^"CameraRig")
		if rig != null and rig.has_method("planar_basis"):
			var basis: Basis = rig.call("planar_basis")
			yaw = atan2(basis.z.x, basis.z.z)

	var creature_pos: Variant = null
	if world != null:
		var follower := world.get_node_or_null(^"AllyCreature")
		if follower != null and is_instance_valid(follower) and follower is Node3D:
			creature_pos = (follower as Node3D).global_position

	_minimap.call("update_view", _player.global_position, yaw, creature_pos)

	var dim := 1.0
	if world != null:
		var combat := world.get_node_or_null(^"CombatManager")
		if combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting")):
			dim = 0.55
	_minimap.call("set_dim", dim)


# --- objective block ---------------------------------------------------------------


## Below the minimap, right-aligned to the same inset.
##
## HUD-POPUP task 3: this used to be naked text with only a legibility
## outline, on the spec's own call ("no giant quest window") -- but a blind
## critic named it and the quest subtext as "the only HUD elements with no
## backing panel, floating on sky and terrain... one lighting change from
## vanishing," and separately measured the subtext itself (`_objective_text_label`,
## `UITokens.FONT_LABEL` = 23) at ~12 physical px, under this HUD's own
## ~16px floor. Both fixed together: a small translucent `panel_box()` behind
## the two labels (the same treatment the creature panel and hotbar already
## wear, not a new "giant window" -- it is exactly `OBJECTIVE_MAX_WIDTH` wide,
## no bigger than the text it holds needs), and the subtext raised to
## `HUD_READABLE_FONT_SIZE` alongside the eyebrow it already sits below.
func _build_objective_block() -> void:
	var right := 1920.0 - UITokens.HUD_INSET
	var top := UITokens.HUD_INSET + MINIMAP_SIZE.y + UITokens.GAP
	var block := Control.new()
	block.name = "ObjectiveBlock"
	_objective_block = block
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.position = Vector2(right - OBJECTIVE_MAX_WIDTH, top)
	block.size = Vector2(OBJECTIVE_MAX_WIDTH, OBJECTIVE_BLOCK_HEIGHT)
	_root.add_child(block)

	var backing := PanelContainer.new()
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.position = Vector2.ZERO
	backing.size = block.size
	# GATE3-HUD-HIERARCHY: WARNING accent -- the "what the game is telling
	# you to do" tier. See `UITokens.panel_box_accent()`'s own header.
	backing.add_theme_stylebox_override("panel", UITokens.panel_box_accent(UITokens.WARNING))
	block.add_child(backing)
	_objective_backing = backing

	var eyebrow := Label.new()
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eyebrow.text = "M A I N   S T O R Y" # letter-spaced feel; no theme letter-spacing support
	# `UITokens.FONT_TINY` (19) measured ~7 physical px at the Ally's real
	# resolution -- same "shared by a dozen screens this lane does not own"
	# reason `HUD_READABLE_FONT_SIZE`'s own header gives for not raising that
	# shared constant; a local override here does the same job this file
	# already does for its other micro-labels.
	eyebrow.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	# HUD-EMPHASIS: `TEXT_MUTED` -> `TEXT_SECONDARY`. A blind critic read the
	## eyebrow as "low-contrast grey-blue over a translucent panel with a tree
	## behind it... it nearly vanishes even at full zoom" -- still the
	## quietest label on the panel (the quest line itself stays
	## `TEXT_PRIMARY`), just no longer the near-background grey that made it
	## disappear against a moving 3D backdrop.
	eyebrow.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	eyebrow.position = Vector2(OBJECTIVE_INSET, OBJECTIVE_INSET)
	eyebrow.size = Vector2(OBJECTIVE_MAX_WIDTH - OBJECTIVE_INSET * 2.0, 34.0)
	block.add_child(eyebrow)
	_objective_eyebrow_label = eyebrow

	_objective_text_label = Label.new()
	_objective_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_text_label.position = Vector2(OBJECTIVE_INSET, OBJECTIVE_EYEBROW_ROW + OBJECTIVE_INSET)
	_objective_text_label.size = Vector2(
		OBJECTIVE_MAX_WIDTH - OBJECTIVE_INSET * 2.0,
		OBJECTIVE_BLOCK_HEIGHT - OBJECTIVE_EYEBROW_ROW - OBJECTIVE_INSET * 2.0
	)
	# HUD-POPUP task 3: was `UITokens.FONT_LABEL` (23, ~10.7 physical px cap
	# height) -- see this function's own header.
	_objective_text_label.add_theme_font_size_override("font_size", HUD_SENTENCE_FONT_SIZE)
	_objective_text_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	# LEFT, not RIGHT (DEFECT 4b, blind visual review of
	# `shots/ui/10-combat-hud.png` and `shots/ui/07-minimap.png`): quest text
	# genuinely long enough to wrap ("Restore the Old Mill Crossing.") right-
	# aligns each wrapped line independently, so a short trailing word like
	# "Crossing." lands flush against the right edge with a wide gap of empty
	# space to its left -- reading as a stray fragment floating apart from the
	# line above it, not the end of a wrapped sentence. Left alignment gives
	# every wrapped line the same starting edge, which is what actually makes
	# it read as one continuing sentence instead of a widow.
	_objective_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_objective_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# BACKLOG-HUD-STORYTRACKER (owner playtest item 21, "takes up too much
	# space"). `tools/_probe_storytracker_footprint.gd` measured every
	# authored tracked line at this block's real width/font: half of them
	# (14/27) wrap past two lines, up to 256px tall against the block's
	# 169px two-line design height (`OBJECTIVE_BLOCK_HEIGHT`) -- the panel was
	# quietly growing 50% taller than intended for the common case, which is
	# the "too much space" the owner is naming. Neither lever left to shrink
	# WITH is free: `HUD_SENTENCE_FONT_SIZE` (32) is already exactly
	# `HUD_SCALE`'s computed floor for sentence-shaped text
	# (`font_size_for_cap_arcmin(SENTENCE_CAP_ARCMIN)` == 32), and narrowing
	# the block (the probe's 268px case) makes the wrap WORSE, not better (19/27
	# hit three-plus lines instead of 14). So the cap goes on line count, not on
	# the two settled levers: the tracker always shows and sizes for at most
	# `OBJECTIVE_LINES`, with a word-boundary ellipsis on whatever doesn't fit.
	# The full sentence is not lost -- `tab_quest_log.gd` already carries the
	# complete objective text; this HUD panel is the at-a-glance pointer, not
	# the only place the line exists.
	_objective_text_label.max_lines_visible = OBJECTIVE_LINES
	_objective_text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	block.add_child(_objective_text_label)


## Runs after `UITokens.make_text_legible(_root)`, which would otherwise
## overwrite a per-widget override applied earlier in `_ready()`. Predates
## `_build_objective_block()`'s own backing panel (HUD-POPUP) and stays on
## top of it as a second line of defence, not a replacement -- the panel
## fixes the "floating on sky and terrain" failure the critic named; this
## outline is what already protected the text before that, and there is no
## reason to trade one contrast guarantee for the other. Roughly 1.5x the
## shared outline both labels already carry, tuned as "clearly heavier," not
## a specific measured target -- unlike the font-size fixes above, no blind
## pass measured a physical contrast ratio for this text against a variable,
## moving 3D background to check it against.
func _strengthen_objective_contrast() -> void:
	var wide_outline := int(round(UITokens.OUTLINE_SIZE * 1.5))
	for label in [_objective_eyebrow_label, _objective_text_label, _objective_hint_label]:
		if label == null:
			continue
		label.add_theme_constant_override("outline_size", wide_outline)
		label.add_theme_color_override("font_outline_color", Color(UITokens.OUTLINE, 1.0))


## The mirror image of `_strengthen_objective_contrast()`: that function
## exists because the objective block had NO plate when its outline had to
## carry the whole contrast burden alone. This corner is the opposite case --
## `_build_vitals_cluster()`'s new plate (HUD-EMPHASIS) now does that job, so
## the same heavy `UITokens.make_text_legible()` outline the plate-less
## version needed is now doing double duty a blind critic named directly:
## "the heavy drop-shadows on 'x12' and those numerals are doing contrast
## work the missing plates should be doing." Runs after
## `make_text_legible(_root)` for the same override-ordering reason
## `_strengthen_objective_contrast()`'s own header gives.
func _soften_vitals_contrast() -> void:
	var soft_outline := int(round(UITokens.OUTLINE_SIZE * 0.4))
	for label in [_hp_value_label, _satiety_caption_label, _satiety_value_label, _satiety_state_label]:
		if label == null:
			continue
		label.add_theme_constant_override("outline_size", soft_outline)
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 0)


## Size the objective block's plate to the tracked line it actually holds.
##
## FOUND WHILE MEASURING `HIST-036`, not looked for, and a defect in its own
## right. `OBJECTIVE_BLOCK_HEIGHT` is a fixed 170, which leaves 94px of interior
## for the tracked line -- and four authored lines wrap past that, the longest
## ("Build a Creature Bed for each of your entrants. 0/3") to 165px. A `Label`
## does not clip by default, so the overflow drew straight out through the
## bottom of `_build_objective_block()`'s backing plate and onto the terrain:
## a 51px spill, measured, and precisely the "floating on sky and terrain, one
## lighting change from vanishing" failure HUD-POPUP added that plate to fix.
##
## This adds no occupied pixels to the HUD -- the text was already drawn there;
## only the plate behind it was missing. `OBJECTIVE_BLOCK_HEIGHT` remains the
## floor and the block is that height exactly for every line that fits, which
## is what the `maxf` says.
##
## BACKLOG-HUD-STORYTRACKER: "every line that fits" used to mean however many
## lines a `Label` with no cap decided to wrap to -- as many as three for half
## the authored objectives (see `_build_objective_block()`'s own header). The
## text label is now capped to `OBJECTIVE_LINES` (`max_lines_visible` +
## word-ellipsis overrun, set once at build time), so the height computed here
## is clamped to match what the label will actually show -- `get_line_count()`
## still reports the UNCLAMPED wrap count, which is why the clamp is applied
## here rather than trusted from the label.
##
## Called on objective change rather than every frame: measuring a wrapped
## label shapes its text, and this panel changes about twenty-five times in a
## chapter.
func _layout_objective_block() -> void:
	if _objective_block == null or _objective_text_label == null:
		return
	var inner_width := OBJECTIVE_MAX_WIDTH - OBJECTIVE_INSET * 2.0
	var text_top := 36.0 + OBJECTIVE_INSET
	var text_floor := OBJECTIVE_BLOCK_HEIGHT - 36.0 - OBJECTIVE_INSET * 2.0

	_objective_text_label.size.x = inner_width
	var shown_lines := mini(_objective_text_label.get_line_count(), OBJECTIVE_LINES)
	var capped_height := float(shown_lines) * float(_objective_text_label.get_line_height())
	var text_height := maxf(text_floor, capped_height)
	_objective_text_label.size = Vector2(inner_width, text_height)

	var height := maxf(OBJECTIVE_BLOCK_HEIGHT, text_top + text_height + OBJECTIVE_INSET)
	_objective_block.size = Vector2(OBJECTIVE_MAX_WIDTH, height)
	if _objective_backing != null:
		_objective_backing.size = _objective_block.size


## A wrapped `Label`'s real height at its current width.
##
## `Label` has no `get_content_height()` in Godot 4.7 -- that is
## `RichTextLabel`'s, and reaching for it here parses but fails at runtime.
## Lines x line height is the number, and it is only correct once the label's
## `size.x` is already the width it will wrap at, so every caller sets that
## first.
func _wrapped_height(label: Label) -> float:
	if label == null:
		return 0.0
	return float(label.get_line_count()) * float(label.get_line_height())


## OBJECTIVE-HINT-ON-HUD (`HIST-036`, OP23-04 / OP23-09). The card that finally
## draws `quest_log.gd::tracked_hint()`, which has been written and tested since
## OP23-04 with nothing rendering it.
##
## See `OBJECTIVE_HINT_CARD_WIDTH`'s header for the measurement that put the
## hint here instead of under the objective block, which is where the backlog
## expected it and where it does not fit at any width or font size the HUD
## allows. Nothing is shortened -- the backlog names shortening the hints as
## explicitly not the fix, because the teaching is the point of them.
##
## Built hidden and sized on reveal: the label wraps against real text, so
## there is no correct height until there is text.
func _build_objective_hint_card() -> void:
	var card := Control.new()
	card.name = "ObjectiveHintCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	# `_build_region_banner()` runs after this one, so the banner's own bottom
	# is read from its authored offset rather than from a node that does not
	# exist yet. `_region_banner_bottom()` is the one place that knows it.
	card.position = Vector2(
		(1920.0 - OBJECTIVE_HINT_CARD_WIDTH) * 0.5,
		_region_banner_bottom() + OBJECTIVE_HINT_CARD_GAP_UNDER_BANNER
	)
	card.size = Vector2(OBJECTIVE_HINT_CARD_WIDTH, 0.0)
	_root.add_child(card)
	_objective_hint_card = card

	var backing := PanelContainer.new()
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.position = Vector2.ZERO
	backing.add_theme_stylebox_override("panel", UITokens.panel_box())
	card.add_child(backing)
	_objective_hint_card_backing = backing

	var inner := OBJECTIVE_HINT_CARD_WIDTH - OBJECTIVE_HINT_CARD_INSET * 2.0

	_objective_hint_label = Label.new()
	_objective_hint_label.name = "CardHint"
	_objective_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_hint_label.position = Vector2(
		OBJECTIVE_HINT_CARD_INSET, OBJECTIVE_HINT_CARD_INSET
	)
	_objective_hint_label.size = Vector2(inner, 0.0)
	_objective_hint_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	# `TEXT_PRIMARY` and centred. The card holds one thing and holds it for a
	# few seconds, so there is no hierarchy inside it to express and nothing to
	# step down from -- and HUD-EMPHASIS already had to move the objective
	# block's eyebrow OFF the quieter colours after a blind critic read them as
	# vanishing against a moving 3D backdrop, which is exactly the background
	# this card sits on.
	_objective_hint_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_objective_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(_objective_hint_label)


## The bottom edge of `_build_region_banner()`'s slot, in authored canvas
## coordinates. Read off the same offsets that function sets, so the card
## under it cannot drift if the banner is ever moved.
func _region_banner_bottom() -> float:
	return REGION_BANNER_TOP + REGION_BANNER_HEIGHT


## Show the card for this rung, or take it down if the rung authors no hint.
##
## Duration is per-hint; see the two `OBJECTIVE_HINT_SECONDS_*` constants.
##
## REVEALING ON WORLD ENTRY IS WANTED, and is worth saying out loud because the
## HUD is rebuilt with `_objective_last_text` empty every time the world scene
## mounts, so the first poll always looks like a change. `GF-B-006` had to fix
## the mirror image of this on the party strip -- a first-poll reveal of an
## EMPTY roster -- and the difference is the content: a player who has just
## loaded into their current rung is exactly the player who needs to be told
## how to finish it. An empty hint reveals nothing either way, which is every
## beat past tournament entry: OP23-04's directive authors `how` for the
## opening ladder only.
func _reveal_objective_hint(hint: String) -> void:
	if _objective_hint_card == null:
		return
	if hint.strip_edges().is_empty():
		_hide_objective_hint_card()
		return

	var inner := OBJECTIVE_HINT_CARD_WIDTH - OBJECTIVE_HINT_CARD_INSET * 2.0
	_objective_hint_label.text = hint
	_objective_hint_label.size.x = inner
	_objective_hint_label.size = Vector2(inner, _wrapped_height(_objective_hint_label))

	var height := OBJECTIVE_HINT_CARD_INSET * 2.0 + _objective_hint_label.size.y
	_objective_hint_card.size = Vector2(OBJECTIVE_HINT_CARD_WIDTH, height)
	_objective_hint_card_backing.size = _objective_hint_card.size
	_objective_hint_card.visible = true

	var words := hint.split(" ", false).size()
	var seconds := OBJECTIVE_HINT_SECONDS_BASE + float(words) * OBJECTIVE_HINT_SECONDS_PER_WORD
	_objective_hint_until = Time.get_ticks_msec() / 1000.0 + seconds


func _hide_objective_hint_card() -> void:
	_objective_hint_until = 0.0
	if _objective_hint_card != null:
		_objective_hint_card.visible = false


## The reveal's own clock. Split from `_update_objective()` because that
## function returns early on the (overwhelmingly common) frame where the
## objective has not changed, which is every frame a reveal is actually
## counting down through.
func _tick_objective_hint() -> void:
	if _objective_hint_until <= 0.0:
		return
	if Time.get_ticks_msec() / 1000.0 < _objective_hint_until:
		return
	_hide_objective_hint_card()


func _update_objective() -> void:
	if _game == null:
		return
	var text := str(_game.get("objective_text"))
	if text == _objective_last_text:
		_tick_objective_hint()
		return
	_objective_last_text = text
	_objective_text_label.text = text
	_reveal_objective_hint(str(_game.get("objective_hint")))
	# An empty tracked line means there is no objective, and a panel is not the
	# way to say that. `quest_log.gd` returns "" once every `main` entry's flag
	# is set -- which is the state the chapter ENDS in, after the legendary
	# choice -- and this block was built once in `_ready()` and never hidden, so
	# a finished game sat there with the eyebrow "MAIN STORY" over a blank line,
	# permanently. Found by a blind cold playtest walking the whole flag chain:
	# 25 steps, every line correct, and then a panel with nothing in it.
	#
	# Hidden rather than emptied, because the backing panel is the visible part.
	if _objective_block != null:
		_objective_block.visible = not text.strip_edges().is_empty()
	_layout_objective_block()


# --- region banner ---------------------------------------------------------------


## Top-centre, well clear of the prompt/hotbar block anchored to the bottom of
## the screen -- a Fortnite-style location card announces itself where the
## player is already looking, not down where their eyes are on the hotbar.
## Naked text, no panel, same "legibility outline instead of a box" call the
## objective block above already makes.
func _build_region_banner() -> void:
	_region_banner = Label.new()
	# Named so a footprint measurement can tell this transient card apart from
	# the persistent HUD; it was an anonymous child of Root and
	# `tools/_measure_hud_footprint.gd` counted its 800x55 box as persistent.
	_region_banner.name = "RegionBanner"
	_region_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_region_banner.visible = false
	_region_banner.anchor_left = 0.5
	_region_banner.anchor_right = 0.5
	_region_banner.offset_left = -400.0
	_region_banner.offset_right = 400.0
	_region_banner.offset_top = REGION_BANNER_TOP
	_region_banner.offset_bottom = REGION_BANNER_TOP + REGION_BANNER_HEIGHT
	_region_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_region_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# HUD-SCALE: 40 -> 34. A region title card is transient and deliberately
	# the loudest text on this HUD, so it keeps a clear lead over the sentence
	# tier (32) and the glance tier (26) -- it is just no longer sized as
	# though it were about to be downscaled by a third.
	_region_banner.add_theme_font_size_override("font_size", 34)
	_region_banner.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_root.add_child(_region_banner)


## Polls `Game.map`'s one-shot queue (`take_pending_region_announcement()`)
## every frame, the same read-and-clear contract `_hotbar_message` already
## uses for its own timed banners -- a region is entered on at most one frame,
## so a plain equality check like `_update_objective()`'s would miss it the
## instant the queue is cleared by this same call.
func _update_region_banner() -> void:
	if _game == null:
		return
	var map: RefCounted = _game.get("map")
	if map == null:
		return
	var text := str(map.call("take_pending_region_announcement"))
	if not text.is_empty():
		_region_banner.text = text
		_region_banner.visible = true
		_region_banner_until = Time.get_ticks_msec() / 1000.0 + REGION_BANNER_SECONDS
	elif _region_banner_until > 0.0 and Time.get_ticks_msec() / 1000.0 >= _region_banner_until:
		_region_banner_until = 0.0
		_region_banner.visible = false


# --- the progression Moment banner (PROGRESSION-VISIBLE, prompt 73 §2.2) ------------

## Top-centre, under `_build_region_banner()`'s slot, sized from
## data/config/progression_feedback.json's `banner` block. Built here rather
## than in the .tscn like every other card on this HUD. Two Labels in a
## plate: the title ("Tup reached Lv 8") in the heading tier and the detail
## ("+4 HP · +1 ATK · +1 DEF · evolution level reached") in the label tier,
## plus an "also" line for a second moment collapsed into the same plate.
func _build_moment_banner() -> void:
	var cfg: Dictionary = PROGRESSION_FEED.config().get("banner", {})
	var width := float(cfg.get("width", 900))
	_moment_banner = PanelContainer.new()
	_moment_banner.name = "MomentBanner"
	_moment_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_banner.visible = false
	_moment_banner.anchor_left = 0.5
	_moment_banner.anchor_right = 0.5
	_moment_banner.offset_left = -width * 0.5
	_moment_banner.offset_right = width * 0.5
	_moment_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_moment_banner.add_theme_stylebox_override("panel", UITokens.panel_box_accent(UITokens.WARNING, UITokens.BG_DEEP))
	_root.add_child(_moment_banner)
	_position_moment_banner()

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	_moment_banner.add_child(column)

	_moment_title = Label.new()
	_moment_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_moment_title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	_moment_title.add_theme_color_override("font_color", UITokens.WARNING)
	column.add_child(_moment_title)

	_moment_detail = Label.new()
	_moment_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_moment_detail.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_moment_detail.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	column.add_child(_moment_detail)

	_moment_also = Label.new()
	_moment_also.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_also.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# FONT_TINY (19) measured ~11px on the judge's 1280x800 ruler and was
	# called too small for a handheld; the also-line carries a real event
	# name, so it sits in the label tier with the rest of the readable HUD.
	_moment_also.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_moment_also.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_moment_also.visible = false
	column.add_child(_moment_also)
	UITokens.make_text_legible(_moment_banner)
	# Present, not history: a HUD mounted after a fight does not replay it.
	_moment_feed_seq = PROGRESSION_FEED.latest_seq()


## The banner's slot, clamped inside the safe area on whatever canvas is
## actually rendering (1080 tall authored, 1200 on the Ally): never above
## `safe_area_fraction` of the height, and never on top of the two cards that
## already own this top-centre lane.
##
## BLIND-JUDGE ROUND 1: the first version cleared only the region banner's
## slot, and the objective HINT CARD sits directly under that
## (`_build_objective_hint_card()`, `_region_banner_bottom() +
## OBJECTIVE_HINT_CARD_GAP_UNDER_BANNER`) and grows downward with its own
## wrapped text. So a Moment landing while a hint was up drew straight
## through it -- the judge read "He is waiting at the table downstairs" and
## the banner headline occupying the same pixels, and called it the worst
## defect in the set. The card's real bottom is measured here, live, rather
## than assumed from its authored offset, because its height depends on how
## many lines the hint wrapped to.
func _position_moment_banner() -> void:
	if _moment_banner == null:
		return
	var cfg: Dictionary = PROGRESSION_FEED.config().get("banner", {})
	var canvas_h: float = _root.size.y if _root != null and _root.size.y > 0.0 else 1080.0
	var safe := canvas_h * float(cfg.get("safe_area_fraction", 0.05))
	var floor_y := maxf(safe, _region_banner_bottom() + UITokens.GAP)
	if _objective_hint_card != null and _objective_hint_card.visible:
		floor_y = maxf(floor_y, _objective_hint_card.position.y + _objective_hint_card.size.y + UITokens.GAP)
	var top := maxf(float(cfg.get("top", 184)), floor_y)
	var height := float(cfg.get("height", 92))
	_moment_banner.offset_top = top
	_moment_banner.offset_bottom = top + height


## Poll the feed for Moments, queue them, and show them when the screen is
## free: never during a fight (they flush at the result beat, when
## `_combat_is_running()` drops), never over a story modal (a dialogue, the
## name prompt, the starter picker) -- the plate is passive and cannot take
## focus, but a moment shown under a conversation is a moment wasted.
func _update_moment_banner() -> void:
	if _moment_banner == null:
		return
	var newest := PROGRESSION_FEED.latest_seq()
	if newest != _moment_feed_seq:
		for raw: Variant in PROGRESSION_FEED.peek_since(_moment_feed_seq):
			var event := raw as Dictionary
			if PROGRESSION_FEED.is_moment(event):
				_moment_queue.append(event)
		_moment_feed_seq = newest

	var now := Time.get_ticks_msec() / 1000.0
	if _moment_banner.visible:
		# The hint card can appear, grow or go away while the banner is up.
		_position_moment_banner()
	if _moment_banner.visible and now >= _moment_until:
		_moment_banner.visible = false
		_moment_cooldown_until = now + PROGRESSION_FEED.seconds("moment_cooldown_seconds", 0.4)

	if _moment_queue.is_empty():
		return
	if _combat_is_running() or _story_modal_is_open():
		return

	var collapse := PROGRESSION_FEED.seconds("moment_collapse_seconds", 5.0)
	if _moment_banner.visible and now - _moment_shown_at < collapse:
		# The owner's rule on noise: a second moment inside the window joins
		# the plate that is already up instead of queueing a second one.
		var event: Dictionary = _moment_queue.pop_front()
		var text: Dictionary = PROGRESSION_FEED.moment_text(event)
		var also := str(text.get("title", ""))
		# BLIND-JUDGE ROUNDS 1 AND 2, both raised it: whichever moment landed
		# FIRST owned the headline, so a level-up arriving a beat after a bond
		# node was relegated to the smallest, dimmest line on the plate --
		# "the level-up should not be the thing hidden in tier three". A
		# level-up outranks a bond node for the headline (the directive asks
		# for it to be "a noticeable audiovisual event"); the one it displaces
		# moves down to the also-line rather than being dropped.
		if str(event.get("kind", "")) == "level_up" and str(_last_moment.get("kind", "")) != "level_up":
			_dress_moment_banner("level_up")
			var displaced := _moment_title.text
			_moment_title.text = str(text.get("title", ""))
			_moment_detail.text = str(text.get("detail", ""))
			_moment_detail.visible = not _moment_detail.text.is_empty()
			also = displaced
		_moment_also.text = also if _moment_also.text.is_empty() or not _moment_also.visible \
				else "%s   ·   %s" % [_moment_also.text, also]
		_moment_also.visible = true
		_moment_until = now + PROGRESSION_FEED.seconds("moment_seconds", 3.0)
		_last_moment = event
		_moment_shown_count += 1
		_play_moment_cue(event)
		return
	if _moment_banner.visible or now < _moment_cooldown_until:
		return

	var next: Dictionary = _moment_queue.pop_front()
	var lines: Dictionary = PROGRESSION_FEED.moment_text(next)
	_dress_moment_banner(str(next.get("kind", "")))
	_moment_title.text = str(lines.get("title", ""))
	_moment_detail.text = str(lines.get("detail", ""))
	_moment_detail.visible = not _moment_detail.text.is_empty()
	_moment_also.text = ""
	_moment_also.visible = false
	_position_moment_banner()
	_moment_banner.visible = true
	_moment_shown_at = now
	_moment_until = now + PROGRESSION_FEED.seconds("moment_seconds", 3.0)
	_last_moment = next
	_moment_shown_count += 1
	_play_moment_cue(next)


## BLIND-JUDGE ROUND 2: a pixel diff of the level-up and milestone banners
## found 1.07% of pixels differing, "none of them in the plate's border,
## headline or second line" -- the two event classes were the same picture.
## They now carry different accents: a level-up is TEAL (the same colour the
## XP sliver and the combat HUD's XP line already use for levelling), a bond
## milestone stays WARNING amber (the colour bond wears everywhere else).
## The sound cues already differ; this makes the plate agree with them.
func _dress_moment_banner(kind: String) -> void:
	var accent: Color = UITokens.TEAL if kind == "level_up" else UITokens.WARNING
	_moment_banner.add_theme_stylebox_override("panel",
		UITokens.panel_box_accent(accent, UITokens.BG_DEEP))
	_moment_title.add_theme_color_override("font_color", accent)


func _play_moment_cue(event: Dictionary) -> void:
	var cue_id := str(PROGRESSION_FEED.config().get("sound_cues", {}).get(str(event.get("kind", "")), ""))
	if cue_id.is_empty():
		return
	var audio_cfg: Dictionary = AUDIO_MANAGER_HUD.section("progression")
	var sfx := str(audio_cfg.get(cue_id, ""))
	if sfx.is_empty():
		return
	AUDIO_MANAGER_HUD.play(sfx, str(audio_cfg.get("bus", "UI")))


## Any story modal (`game_menu.gd::STORY_MODAL_GROUP`: dialogue, name prompt,
## starter picker) currently up.
func _story_modal_is_open() -> bool:
	for node: Node in get_tree().get_nodes_in_group(GAME_MENU_HUD.STORY_MODAL_GROUP):
		if node.has_method("is_open"):
			if bool(node.call("is_open")):
				return true
		elif node is CanvasItem and (node as CanvasItem).visible:
			return true
	return false


## Evidence accessors for the progression smoke.
func moment_banner_visible() -> bool:
	return _moment_banner != null and _moment_banner.visible


func moment_banner_rect() -> Rect2:
	return _moment_banner.get_global_rect() if _moment_banner != null else Rect2()


func moment_banner_text() -> String:
	if _moment_banner == null:
		return ""
	return "%s | %s | %s" % [_moment_title.text, _moment_detail.text, _moment_also.text]


func moments_shown() -> int:
	return _moment_shown_count


func last_moment() -> Dictionary:
	return _last_moment


func moments_queued() -> int:
	return _moment_queue.size()


func creature_xp_line() -> String:
	return _creature_xp_label.text if _creature_xp_label != null else ""


# --- day/time readout -------------------------------------------------------------


## Owner playtest 2026-08-30B, item 19: no on-screen way to tell what day it
## is or how far through it the player is. Display only -- this reads
## `Game.day` and `WorldLook`'s own clock, it does not touch either. Naked
## text, no panel, same call `_build_region_banner()` above already makes for
## this same top-centre lane: a persistent line has even less excuse to spend
## a plate on itself than a transient one does.
func _build_daytime_readout() -> void:
	_daytime_label = Label.new()
	_daytime_label.name = "DaytimeReadout"
	_daytime_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daytime_label.anchor_left = 0.5
	_daytime_label.anchor_right = 0.5
	_daytime_label.offset_left = -200.0
	_daytime_label.offset_right = 200.0
	_daytime_label.offset_top = DAYTIME_READOUT_TOP
	_daytime_label.offset_bottom = DAYTIME_READOUT_TOP + DAYTIME_READOUT_HEIGHT
	_daytime_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_daytime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daytime_label.add_theme_font_size_override("font_size", DAYTIME_READOUT_FONT_SIZE)
	_daytime_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	_daytime_label.text = daytime_readout_text(1, 0.0)
	_root.add_child(_daytime_label)


## `_world_look` is looked up lazily, the same defensive `is_instance_valid`
## re-check `_refresh_game_ref()` uses for `_game` -- `_ready()` can run
## before `MeadowsPlayground`'s own children are all in the tree, and a
## capture rig or an isolated test scene may mount this HUD with no
## `WorldLook` sibling at all.
func _update_daytime_readout() -> void:
	if _daytime_label == null or _game == null:
		return
	if not is_instance_valid(_world_look):
		var scene := get_tree().current_scene if is_inside_tree() else null
		_world_look = scene.get_node_or_null(^"WorldLook") if scene != null else null
	var hour := float(_world_look.call("hour")) if _world_look != null else 0.0
	_daytime_label.text = daytime_readout_text(int(_game.get("day")), hour)


# --- frame / lifecycle ---------------------------------------------------------------


func _on_landed(impact_speed: float, damage: float) -> void:
	_peak_fall = maxf(_peak_fall, impact_speed)
	_last_damage = damage


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_debug_level = (_debug_level + 1) % 3
		PERF_TRACE.set_enabled(_debug_level != DEBUG_OFF)
		_debug_readout.visible = _debug_level != DEBUG_OFF


## Perf readout first, always (see `_debug_text`'s header). Everything else
## polls in a fixed order: `_game` refreshed once, hotbar (functionally
## unchanged), the creature block/party strip/objective (all `Game`-sourced), the
## minimap (bake-once then update), then player-sourced vitals/stamina last,
## behind the same null-player / null-vitals guards the old HUD used --
## a capture tool or a headless smoke boot with no player still gets every
## `Game`-sourced block drawn correctly.
func _process(delta: float) -> void:
	if _debug_level == DEBUG_OFF:
		_run_frame(delta)
		return
	var t0 := Time.get_ticks_usec()
	_run_frame(delta)
	PERF_TRACE.record("HUD", Time.get_ticks_usec() - t0)


## The HUD's actual per-frame work, split out of `_process` so the readout can
## time it without timing itself.
func _run_frame(delta: float) -> void:
	if _debug_level != DEBUG_OFF:
		_sample_frame(delta)
		_since_readout += delta
		if _since_readout >= READOUT_INTERVAL:
			_since_readout = 0.0
			_debug_readout.text = _debug_text()

	_refresh_game_ref()
	_yield_bottom_to_build_menu()
	_update_hotbar_and_message()
	_update_world_message()
	_read_hotbar_input()
	_read_world_hotkeys()
	_update_creature_block()
	# After the creature block's content is written for this frame, not
	# before: `_reflow_left_stack()` measures the creature panel's real
	# combined-minimum-size, so it has to run once this frame's text/energy
	# bar visibility is actually in place, or it is always one frame stale.
	_reflow_left_stack()
	_update_party_strip()
	# AFTER `_update_party_strip()`, not alongside `_yield_bottom_to_build_menu()`
	# above: `_update_party_strip()` can call `party_strip.gd::show_strip()` on
	# any frame the roster actually changes (a catch, a level, a faint), which
	# sets the widget's own `.visible = true` again — running the combat yield
	# first would have that overwrite this frame's hide the instant anything
	# in the party moved. Running last gives this the final word every frame.
	_yield_left_stack_to_combat_hud()
	_update_objective()
	_update_region_banner()
	_update_moment_banner()
	_update_daytime_readout()
	_update_exploration_legend()
	_ensure_minimap_baked()
	_update_minimap()
	_update_aim_fade(delta)

	if _player == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		return
	_update_vitals_cluster(vitals, delta)
	_update_stamina_arc(vitals, delta)


func _sample_frame(delta: float) -> void:
	_frame_ms[_frame_head] = delta * 1000.0
	_frame_head = (_frame_head + 1) % FRAME_WINDOW
	_frame_filled = mini(_frame_filled + 1, FRAME_WINDOW)


func _perf_lines() -> Array[String]:
	var worst := 0.0
	var best := 0.0
	var total := 0.0
	if _frame_filled > 0:
		best = _frame_ms[0]
		for i in _frame_filled:
			var ms: float = _frame_ms[i]
			total += ms
			worst = maxf(worst, ms)
			best = minf(best, ms)
	var avg: float = total / float(_frame_filled) if _frame_filled > 0 else 0.0

	var vp := get_viewport()
	var scale: float = vp.scaling_3d_scale if vp != null else 1.0
	var size: Vector2i = vp.get_visible_rect().size if vp != null else Vector2i.ZERO

	var vsync := -1
	if DisplayServer.get_name() != "headless":
		vsync = int(DisplayServer.window_get_vsync_mode())

	var lines: Array[String] = [
		"perf (F3 again for movement/input, once more to hide)",
		"",
		"fps        %d      frame %.1f ms   min %.1f   max %.1f" % [
			Engine.get_frames_per_second(), avg, best, worst,
		],
		"draw calls %d      primitives %d" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		],
		"video mem  %.0f MB   textures %.0f MB" % [
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MB,
		],
		"static mem %.0f MB   nodes %d" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / MB,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		],
		"cpu        process %.2f ms   physics %.2f ms" % [
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		],
		"3d scale   %.2f  (%d x %d)   msaa %d" % [
			scale, int(size.x * scale), int(size.y * scale),
			int(vp.msaa_3d) if vp != null else 0,
		],
		"vsync      %d      max_fps %d" % [vsync, Engine.max_fps],
		_hardware_line,
	]
	lines.append_array(_top_cost_lines())
	return lines


## PERF-ROG / OP23-01: the three subsystems asking for the most CPU right now.
##
## "The frame costs 40ms" is what the owner already knew. Which THING costs it
## is what a playtest could not report, and is the difference between a bug
## report and a fix -- OP23-01's own root cause (`interaction_arbiter`, 20ms a
## frame polling 24,461 prompt providers to find two) was invisible from inside
## the game until this existed. Ranked by work-per-second rather than
## work-per-call, because the scatter's collision sweep runs twice a second and
## the arbiter runs sixty times, and a per-call ranking puts them in the wrong
## order. Instrumentation is live only while this readout is (`perf_trace.gd`).
func _top_cost_lines() -> Array[String]:
	var rows: Array = PERF_TRACE.top(3)
	if rows.is_empty():
		return ["", "top costs   (measuring...)"]
	var out: Array[String] = ["", "top costs  ms/s   per call   rate"]
	for row: Dictionary in rows:
		out.append("  %-22s %6.1f  %6.2f ms  %5.1f Hz" % [
			row["label"], row["ms_per_second"], row["ms"], row["hz"]])
	return out


func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = "" if _prompt_belongs_to_combat() else text
	_fit_prompt_pill()


## True when the arbiter's winning offer came from the encounter director —
## whose lines ("Engage X", "Call out Biscuit") CombatHUD renders in its own
## combat-styled row. Rendering them here too put the same sentence on
## screen twice, which a blind visual review read as a bug the moment the
## two rows stopped sitting at the same pixel. Duck-typed on
## `owns_active_prompt`, a method only the director carries.
func _prompt_belongs_to_combat() -> bool:
	if _arbiter == null or not is_instance_valid(_arbiter):
		return false
	var winner: Object = _arbiter.call("winning_provider")
	return winner != null and winner.has_method("owns_active_prompt")


## RG3's small, always-present answer to "what can I do from the field?".
## Situation-specific verbs remain exclusively in `Prompt`; this row contains
## only persistent world shortcuts. A single RichTextLabel keeps the
## relationship compact and makes device changes atomic -- there cannot be one
## stale keyboard chip beside three updated controller chips for a frame.
##
## OP21-11: mounted into `Root/BottomDock`'s VBoxContainer, not `_root`
## directly, and moved to sit right after `HotbarPanel` (index 1, ahead of
## `Prompt`) -- literally "under the hotbar," and laid out by the same
## container that already keeps the hotbar and the contextual prompt from
## overlapping (see the .tscn's own long comment on why BottomDock exists).
## `size_flags_horizontal = SHRINK_END` matches `HotbarPanel`'s own flag so
## both hug the same right-hand safe zone instead of the legend spanning the
## full authored width behind the player's back.
func _build_exploration_legend() -> void:
	var dock: VBoxContainer = $Root/BottomDock

	_exploration_legend = PanelContainer.new()
	_exploration_legend.name = "ExplorationLegend"
	_exploration_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exploration_legend.custom_minimum_size = LEGEND_SIZE
	_exploration_legend.size_flags_horizontal = Control.SIZE_SHRINK_END
	# GATE3-HUD-HIERARCHY: the persistent capability row (with `HotbarPanel`)
	# recedes on `panel_deep_box()` -- see `_style_hotbar()`'s own header.
	_exploration_legend.add_theme_stylebox_override("panel", UITokens.panel_deep_box())
	dock.add_child(_exploration_legend)
	dock.move_child(_exploration_legend, 1)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	# No vertical margin here -- the panel style already contributes 16px top
	# and 16px bottom (see `LEGEND_SIZE`'s own comment above).
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 0)
	_exploration_legend.add_child(margin)

	_exploration_legend_label = RichTextLabel.new()
	_exploration_legend_label.name = "Label"
	_exploration_legend_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exploration_legend_label.bbcode_enabled = true
	_exploration_legend_label.fit_content = false
	_exploration_legend_label.scroll_active = false
	_exploration_legend_label.shortcut_keys_enabled = false
	_exploration_legend_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exploration_legend_label.add_theme_font_size_override("normal_font_size", LEGEND_FONT_SIZE)
	margin.add_child(_exploration_legend_label)
	UITokens.make_text_legible(_exploration_legend_label)


func _update_exploration_legend() -> void:
	if _exploration_legend == null:
		return
	var should_show := _exploration_legend_should_show()
	_exploration_legend.visible = should_show
	if not should_show:
		return
	var gamepad := INPUT_GLYPH.using_gamepad()
	var revision := int(_party.get("revision")) if _party != null else -1
	# A blind visual critic, shown only the frames, called this out: "RB Call
	# out Biscuit" floating above a legend that also says "RB Call Out" --
	# "same button, two labels, ten pixels apart". The legend's own comment
	# below claims RB is "the one world verb with no other on-screen home",
	# and that is exactly false in the moment the contextual prompt is
	# naming it. The specific line wins; the legend is the fallback.
	# BOTH phrasings of the contextual line, not just "Call out". The offer is
	# "Put <name> away" whenever the creature is actually standing in the
	# world, and matching only the stowed wording left the legend drawing its
	# own "Call Out" entry underneath a prompt that said the opposite -- the
	# same button, two labels ten pixels apart, saying contradictory things.
	var prompt_owns_recall := _prompt_label != null \
			and (_prompt_label.text.contains("Call out")
				or _prompt_label.text.contains(" away"))
	var creature_is_out := _active_creature_is_out(_party != null and int(_party.call("size")) > 0)
	if _legend_was_drawn and gamepad == _legend_last_gamepad \
			and revision == _legend_last_party_revision \
			and prompt_owns_recall == _legend_last_prompt_owned_recall \
			and creature_is_out == _legend_last_creature_was_out:
		return
	_legend_was_drawn = true
	_legend_last_gamepad = gamepad
	_legend_last_party_revision = revision
	_legend_last_prompt_owned_recall = prompt_owns_recall
	_legend_last_creature_was_out = creature_is_out
	_exploration_legend_label.text = _exploration_legend_text(prompt_owns_recall, creature_is_out)


func _exploration_legend_should_show() -> bool:
	if _combat_is_running() or _build_menu_is_open():
		return false
	if _game != null and str(_game.get("pending_build")) != "":
		return false
	if _arbiter != null and is_instance_valid(_arbiter) \
			and not bool(_arbiter.call("enabled")):
		return false
	return INPUT_OWNER.current(get_tree()) == null


func _exploration_legend_text(prompt_owns_recall: bool = false,
		creature_is_out: bool = false) -> String:
	var normal := UITokens.TEXT_PRIMARY
	var change_tint := normal if _cycleable_party_count() > 1 else UITokens.TEXT_MUTED
	# CONTROLLER-MAP: Torch left this legend with its button -- it is a hotbar
	# tool now, select it on the bar and press interact -- so a legend line
	# naming a pad button for it would be naming a button that does something
	# else (B is satchel slot 1). Its keyboard shortcut survives and is still
	# listed in Settings > Controls. Call Out took the space it used to sit
	# in, because RB is the one world verb with no other on-screen home.
	#
	# HUD-INPUT-0903 (owner playtest 2026-09-03: "there should be a shortcut
	# button to map and to building"). Build gets its OWN line back here,
	# unlike Torch: `build_shortcut` (LT / keyboard B, same key `build_open`
	# already used) is a real, direct binding rather than the
	# hammer-then-interact route, so naming its button is naming a button that
	# genuinely does this on both devices.
	var entries: Array[String] = [
		_legend_entry("map", "Map", normal),
		_legend_entry("inventory", "Satchel", normal),
		_legend_entry("build_shortcut", "Build", normal),
	]
	# Stand down while the contextual prompt directly above is already naming
	# this button, with the creature's actual name on it. Two labels for one
	# button, ten pixels apart, is worse than one.
	# OWNER DIRECTIVE 2026-08-23 §3 lands here. With the build hammer out the
	# director stops publishing its creature line so Build can own Interact,
	# and this legend -- sitting beside Change Creature, which is the
	# party-cycle button -- is where the verb goes for the duration. It has to
	# carry the right word to be worth having: "Call Out" over a creature that
	# is already standing there names the wrong half of a toggle.
	if not prompt_owns_recall:
		entries.append(_legend_entry("creature_recall",
			"Put Away" if creature_is_out else "Call Out", normal))
	entries.append(_legend_entry("party_cycle", "Change Creature", change_tint))
	return "     ".join(entries)


func _legend_entry(action: String, label: String, tint: Color) -> String:
	return "%s  [color=#%s]%s[/color]" % [
		INPUT_GLYPH.icon(action, LEGEND_GLYPH_PX, tint), tint.to_html(true), label,
	]


func _cycleable_party_count() -> int:
	if _party == null:
		return 0
	var count := 0
	for member: Variant in _party.call("members"):
		var creature := member as RefCounted
		if creature != null and not bool(creature.get("fainted")) \
				and not bool(creature.get("resting")):
			count += 1
	return count


## Caches the `Game` autoload lookup and the `party` RefCounted it exposes.
## Looked up by path rather than the bare autoload name so a HUD instanced
## without `Game` running (a capture tool, an isolated test scene) just shows
## nothing here instead of crashing -- same convention `sequence_director.gd`
## uses.
func _refresh_game_ref() -> void:
	if not is_instance_valid(_game):
		_game = get_node_or_null(^"/root/Game")
	if _game != null:
		_party = _game.get("party") as RefCounted


func _update_hotbar_and_message() -> void:
	if _game == null:
		return
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		return
	_update_hotbar(inventory)
	if _hotbar_message_until > 0.0 and Time.get_ticks_msec() / 1000.0 >= _hotbar_message_until:
		_hotbar_message_until = 0.0
		_hotbar_message.visible = false


## The hotbar draws `Game.hotbar` — five item ids the player assigned, NOT
## satchel slots 0-4.
##
## It used to mirror the satchel directly, which is why the owner found wood
## and stone occupying action slots that answered "is not something you can
## use here", and why the 2026-08-15 blind playtest (PT-11) watched a potion
## silently leave slot 2 when the backpack was rearranged. A slot now names an
## item and looks up whatever stack currently holds it, so sorting the bag,
## splitting a stack, or spending the last one and picking another up all
## leave the binding alone. A bound item the satchel has none of draws greyed
## with a zero rather than disappearing — the habit survives running out.
##
## Blind visual review: the old chip drew glyph + "Name xN" text at 13px,
## illegible at handheld distance. The backpack already owns telling the
## player an item's NAME (`tab_backpack.gd`); this chip's only job is "what
## is it, how many" at a glance, so it now draws the input glyph, the item's
## own icon art (`items.json`'s `icon` field) at 28px, and the count at 16px
## — no name text at all. Durability-bearing tools keep their `n/max` reading
## in place of a plain count, unchanged from before.
func _update_hotbar(inventory: RefCounted) -> void:
	var db: RefCounted = _game.get("items")
	if db == null:
		return
	var assignments: Array = _game.get("hotbar") as Array
	# A completely empty bar fills itself from what the player is carrying.
	# That covers a brand new game -- Grandpa hands over orbs, potions, berries
	# and revives in one conversation, and a bar that stayed blank until the
	# player found the assign verb would read as broken. The condition is
	# deliberately "ALL five empty", not "any empty": once a single slot is
	# bound the bar is the player's, and nothing rearranges it behind them.
	# That is the whole complaint PT-11 recorded against the old mirror.
	if not assignments.is_empty() and assignments.count("") == assignments.size():
		_game.call("autofill_hotbar")
		assignments = _game.get("hotbar") as Array
	for i in HOTBAR_SLOTS:
		var id := str(assignments[i]) if i < assignments.size() else ""
		# The satchel slot currently holding this item, or -1 for "assigned but
		# carrying none". Everything below reads from the LIVE slot, so a stack
		# that moved in the bag keeps drawing its real count here.
		var slot := int(inventory.call("find_slot", id)) if not id.is_empty() else -1
		var stack: Dictionary = inventory.call("stack_at", slot) if slot >= 0 else {}
		# 28 -> 36: this call used to override `icon()`'s own documented 36px
		# floor ("the smallest step that read clearly" -- see that function's
		# header) down to 28, the one glyph call on this whole HUD that did.
		# A blind critic separately flagged the hotbar numerals as visibly
		# more pixelated than the legend's -- same vendored PNGs, same
		# `icon()` call, the only difference was this smaller target size.
		var glyph := INPUT_GLYPH.icon(HOTBAR_ACTIONS[i], HOTBAR_GLYPH_PX)
		var text: String
		if id.is_empty():
			# Blank second line, not a "-" glyph: a blind critic read the old
			# dash as "a ~2px dark dot artifact" in every empty slot at
			# handheld distance -- a single punctuation character has nothing
			# to read once it is downscaled that far. An empty slot now draws
			# cleanly empty instead of a mark nobody can identify.
			text = "%s\n" % glyph
		else:
			var icon_path := str(db.call("definition", id).get("icon", ""))
			var tool_max: int = int(inventory.call("max_durability_at", slot)) if slot >= 0 else 0
			var count_text: String
			if tool_max > 0:
				count_text = "%d/%d" % [int(inventory.call("durability_at", slot)), tool_max]
			else:
				count_text = "x%d" % int(stack.get("n", 0))
			# The count text's OWN colour, not `items.json`'s `colour` field --
			# that field is a slot-tile TINT (`item_db.gd::colour()`'s own
			# header calls it exactly that), never designed to be read as
			# foreground text. A blind critic could not read "berries"'s tile
			# tint (#a33a55, dark crimson) as the "x12" count text against the
			# hotbar's dark navy panel without 4x magnification -- the one
			# number in the hotbar that actually matters. Out-of-stock still
			# greys, same as before; in-stock now reads at full contrast.
			var text_colour := Color(0.4, 0.42, 0.39) if stack.is_empty() else UITokens.TEXT_PRIMARY
			var icon_bbcode := "[img=%dx%d]%s[/img]" % [HOTBAR_ICON_PX, HOTBAR_ICON_PX, icon_path] \
				if not icon_path.is_empty() else ""
			# 16 -> 34: 16 authored ~= 7 physical px at the Ally's real
			# resolution, the smallest text on the whole HUD and, per the
			# blind critic, illegible without magnification.
			# Icon on its own line, count beneath it. Both used to share one
			# line, and a tool's durability ("40/40" -- the starting axe) needs
			# ~119px beside a 28px icon against ~104px of inner slot width, so
			# with `scroll_active = false` the count was cut mid-glyph in every
			# frame the quickbar appeared in. The slot grew taller rather than
			# wider (see the note on Slot1 in `playground_hud.tscn`): the dock
			# is right-aligned and cannot move left without covering the central
			# focus lane `smoke_prompt_hotbar_dock.gd` guards, so width was the
			# one axis with nothing to give.
			# GF-B-005: ITEM FIRST, binding underneath.
			#
			# The order used to be glyph, icon, count -- the binding badge on
			# the top line, at the largest size in the slot, over an item icon
			# drawn at 28. Reading top to bottom, the first thing the slot said
			# was which button it was on, and the four d-pad badges say that
			# identically (see `HOTBAR_ICON_PX`). Now the icon leads at 64 and
			# the badge sits under it with the count, which is the hierarchy the
			# quick-bar is for: what is in the slot, then how to reach it.
			#
			# The badge keeps `HOTBAR_GLYPH_PX` rather than shrinking to make
			# the point: 36 authored is exactly `MIN_PHYSICAL_GLYPH_PX` at the
			# Ally's real content scale (36 * 0.667 = 24), so it is already at
			# this HUD's legibility floor and cannot go smaller.
			# `smoke_hud_handheld_legibility.gd` asserts that floor directly.
			#
			# Three lines, not two with the badge and the count sharing one:
			# the slot is 112 wide (~104 inner) and a tool's durability
			# ("40/40" at `HOTBAR_COUNT_FONT_SIZE`) needs ~95px on its own, so
			# a badge beside it overflows and `scroll_active = false` cuts it
			# mid-glyph -- the exact defect the old comment on this format
			# string recorded. The slot grew instead (see the note on Slot1 in
			# `playground_hud.tscn`); height is the axis with room.
			text = "%s\n%s\n[font_size=%d][color=#%s]%s[/color][/font_size]" % [
				icon_bbcode, glyph, HOTBAR_COUNT_FONT_SIZE, text_colour.to_html(false), count_text
			]
		if text != _hotbar_last_text[i]:
			_hotbar_last_text[i] = text
			_hotbar_slots[i].text = text


func _read_hotbar_input() -> void:
	if _game == null:
		return
	# OW10: one gate, shared with `_read_world_hotkeys`. This poll used to carry
	# its own two-thirds of the answer (a fight, the arbiter's modal flag) and
	# not the third -- `_build_menu_is_open()` was written onto the world-hotkey
	# poll alone -- which is exactly why the hotbar leaked under an open build
	# menu and the hammer did not.
	# CONTROLLER-MAP: the hotbar STAYS LIVE in a fight. The owner's map puts
	# slots 1-5 on B and the d-pad "in every context including combat, so food
	# and orbs stay reachable mid-fight" -- and nothing else on the pad reads
	# those five buttons during a fight any more, which is what makes that safe.
	# The aim is still excluded: while an orb is being aimed, B is the back-out
	# and X is the release, and a hotbar press underneath either would be the
	# same one-press-two-verbs bug in a smaller window.
	if not _world_input_allowed(false, true):
		return
	if _combat_is_aiming():
		return
	for i in HOTBAR_SLOTS:
		if Input.is_action_just_pressed(HOTBAR_ACTIONS[i]):
			_use_hotbar_slot(i)
			return


## The same defensive CombatManager lookup the minimap dim uses; false when
## no world or no manager is reachable, so menus and tests are unaffected.
func _combat_is_running() -> bool:
	var world := get_tree().get_current_scene()
	if world == null:
		return false
	var combat := world.get_node_or_null(^"CombatManager")
	return combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting"))


## Same defensive lookup, one method further: is that fight currently AIMING
## a throw. Split from `_combat_is_running()` rather than folded into it —
## the aim fade (spec §10.1) only wants the narrower condition, and every
## other `_combat_is_running()` call site (the hotbar gate) has no reason to
## also ask about aiming.
func _combat_is_aiming() -> bool:
	var world := get_tree().get_current_scene()
	if world == null:
		return false
	var combat := world.get_node_or_null(^"CombatManager")
	return combat != null and combat.has_method("is_aiming") and bool(combat.call("is_aiming"))


## Stands down the whole left stack -- `_creature_block`, `_party_strip`, and
## `_vitals_cluster` -- for the length of a fight.
##
## `_creature_block` ("ACTIVE COMPANION" -- name, level, HP, energy) and
## `_party_strip` ("TEAM n / 5") are here because `combat_hud.gd` draws its
## own copy of both: a second, independent `party_strip.gd` mount for
## mid-fight switching, and the active creature's name/level/HP/energy again
## in `AllyPanel` (`_draw_ally()`). Leaving this HUD's versions up named the
## same creature in three places on screen at once and let combat's higher
## `UITokens.LAYER_COMBAT` CanvasLayer win the pixels, exactly the frame a
## blind critic captured (`shots/ui/10-combat-hud.png`: "TEAM 5/5" printing
## straight through a companion panel's own "120 / 120").
##
## `_vitals_cluster` (the player's own FOOD/buffs) and `_health_bar_cluster`
## (the player's own HP, split out to its own bottom-left widget by
## HUD-BACKLOG-20) join them here too -- DEFECT 1, the worst-ranked finding
## in the same critique. Neither has a `combat_hud.gd` twin the way the other
## two do; the reason they stand down anyway is the geometry, not
## duplication: `vitals_position()` and `player_health_bar_position()` both
## place their widget in the exact bottom-left corner `combat_hud.gd` needs
## for its own `AllyPanel`/`PartyStrip`, so leaving either up let a ghosted
## "100 / 100" and "FOOD 100%" print straight through combat's roster
## (`shots/ui/10-combat-hud.png`, `shots/ui/11-capture-reticle.png`). CLAUDE.md
## is explicit that the human never fights -- creature combat is real-time
## and directly piloted, and nothing in a fight can move the trainer's own
## HP -- so nothing this cluster shows is actually ABOUT the fight on screen;
## satiety keeps draining in the background regardless, same as it does
## through a menu, a conversation, or a build session, none of which keep
## this cluster up either. Relocating it instead of hiding it was considered
## and rejected: the only screen corner combat leaves clear (bottom-right) is
## already `combat_hud.gd`'s own move grid, so a rework big enough to find it
## a genuinely free corner is a lot more risk than folding it into a stand-down
## mechanism its two neighbours already use correctly.
##
## The minimap and objective block have no equivalent anywhere in
## `combat_hud.gd` AND sit in a screen corner combat's own UI never reaches
## (top-right) -- neither problem `_vitals_cluster` has -- so they stay
## deliberately out of this function; hiding them would take away information
## combat never replaces, for a collision that does not exist.
##
## Plain `.visible` writes, not a fade: `_creature_block` is a bare `Control`
## with no animation of its own, `_vitals_cluster` and `_health_bar_cluster`
## only ever animate their own `modulate.a` (`_update_vitals_cluster`'s idle
## fade drives both), never `.visible`, and
## `party_strip.gd::_process` already early-returns its fade-timer bookkeeping
## whenever `not visible` (`if _pinned or not visible: return`), so forcing it
## off here cannot fight the widget's own reveal/hide tween -- it simply
## pauses mid-state and picks up again once this sets `.visible = true` back
## on the frame the fight ends, which is also the frame
## `_update_creature_block()`/`_update_party_strip()`/`_update_vitals_cluster()`
## next redraw real content into all three, so nothing stale is left showing.
func _yield_left_stack_to_combat_hud() -> void:
	var combat := _combat_is_running()
	if _creature_block != null:
		_creature_block.visible = not combat
	if _party_strip != null:
		_party_strip.visible = not combat
	# HUD-BACKLOG-20: the HP row's own widget, standing down for combat
	# for the same reason `_vitals_cluster` does -- nothing this shows is
	# about the fight (the human never fights), and `combat_hud.gd` wants
	# this same bottom-left corner for its own `AllyPanel`/`PartyStrip`. ALSO
	# standing down whenever the bottom dock does (`_bottom_dock_should_yield()`)
	# -- this widget's lower position sits inside `dialogue_panel.gd`'s own
	# fixed-bottom-edge box (`smoke_dialogue_clears_the_world_hud.gd` caught
	# the real overlap), the same reason the hotbar and prompt already yield
	# to it.
	#
	# OWNER-0902-HUD-TEAM-MENU: `_vitals_cluster` now sits directly beside
	# this widget instead of up in the roster column (`vitals_position()`'s
	# own header), so it shares BOTH reasons to stand down, not just combat --
	# it is exactly as much inside `dialogue_panel.gd`'s box now as the health
	# bar always was. One shared condition for both, rather than two that
	# could silently drift apart again.
	var vitals_visible := not combat and not _bottom_dock_should_yield()
	if _vitals_cluster != null:
		_vitals_cluster.visible = vitals_visible
	# Both conditions combine in this one write, run last in
	# `_run_frame()`, so this and `_yield_bottom_to_build_menu()` (which runs
	# earlier and cannot see the combat flag) never fight over the final
	# value the way a second, independent write would.
	if _health_bar_cluster != null:
		_health_bar_cluster.visible = vitals_visible
	_yield_creature_block_to_party_strip()


## GF-B-006: the single-creature panel stands down for as long as the roster
## reveal is up.
##
## The two now share the left column -- see `party_strip_position()`'s header
## for why there is nowhere else on this canvas to put a five-row roster that is
## not over the player's forward view. They are never both needed: the panel
## names the ACTIVE creature, and the strip names the active creature with its
## four team-mates around it and the active one's own row rail lit. Hiding the
## subset while the superset is up is what makes HUD-POPUP's compositing defect
## impossible rather than merely avoided -- two disjoint rects still both draw.
##
## Runs LAST, after `_yield_left_stack_to_combat_hud()`'s own writes above, for
## the same reason that function runs after `_update_party_strip()`: whichever
## write happens last this frame is the one that survives, and a fight must
## still take the whole column down regardless of what the roster is doing.
func _yield_creature_block_to_party_strip() -> void:
	if _creature_block == null or _party_strip == null:
		return
	if _party_strip.visible:
		_creature_block.visible = false


func _use_hotbar_slot(slot_index: int) -> void:
	var inventory: RefCounted = _game.get("inventory")
	var db: RefCounted = _game.get("items")
	if inventory == null or db == null:
		return

	# `slot_index` is a position on the BAR; the id it names is the thing being
	# used, and its satchel slot is looked up fresh every press.
	var assignments: Array = _game.get("hotbar") as Array
	var id := str(assignments[slot_index]) if slot_index < assignments.size() else ""
	if id.is_empty():
		_show_hotbar_message("Nothing on that slot yet — assign one from the backpack.")
		return
	var index := int(inventory.call("find_slot", id))
	if index < 0:
		_show_hotbar_message("Out of %s." % str(db.call("item_name", id)))
		return
	var stack: Dictionary = inventory.call("stack_at", index)
	if stack.is_empty():
		return

	# Owner directive: "press slot, tool in hand". A tool slot EQUIPS now --
	# pressing it again puts the tool away, so one button is both draw and
	# stow. Repair moved to the backpack's own Use verb (`tab_backpack.gd`),
	# which is where it always belonged: free repair was the only thing a tool
	# press did before this, and it is why the owner could carry an axe for a
	# whole session without ever seeing one.
	if str(db.call("kind", id)) == "tool":
		var item_name := str(db.call("item_name", id))
		if str(_game.get("equipped_tool")) == id:
			_game.set("equipped_tool", "")
			_show_hotbar_message("Put the %s away." % item_name.to_lower())
			return
		# A tool worn down to nothing still equips -- it just gathers like bare
		# hands until repaired, which `harvest_logic.gd` already decides. Saying
		# so here beats letting the player wonder why the swing yields less.
		var maximum := int(inventory.call("max_durability_at", index))
		var current := int(inventory.call("durability_at", index))
		_game.set("equipped_tool", id)
		if maximum > 0 and current <= 0:
			_show_hotbar_message("%s in hand — but it's blunt. Repair it at the bench." % item_name)
		else:
			_show_hotbar_message("%s in hand." % item_name)
		return

	# D40 (OF32): `heal` (potions) and `revive` (Revives) are mutually
	# exclusive fields on an item's definition -- a potion tops up the
	# living, a Revive raises the fallen, and never the same item both ways.
	var definition := db.call("definition", id) as Dictionary
	var heal := float(definition.get("heal", 0.0))
	var revive_fraction := float(definition.get("revive", 0.0))

	# Food. This bar could not eat berries at all once -- pressing them here
	# answered "Berries is not something you can use here", which is the kind of
	# inconsistency that teaches a player the bar is unreliable. Same call, same
	# buff dictionary, so one food item cannot behave two ways depending on
	# which screen reached it.
	#
	# T5-CARE: the sentence that used to open this comment -- "the backpack
	# could always eat berries" -- had stopped being true. D68 gave berries a
	# `creature_food` key and `tab_backpack.gd::_read_use()` tests that BEFORE
	# `satiety`, so from the satchel the only food in the game routed to a
	# creature picker with no row for the player, and this bar became the only
	# way to eat. The satchel's picker now carries the trainer's own row, so the
	# two screens agree again.
	var satiety := float(definition.get("satiety", 0.0))
	if satiety > 0.0:
		var vitals := _game.call("player_vitals") as RefCounted
		if vitals == null:
			_show_hotbar_message("Nothing to eat that here.")
			return
		vitals.call("eat", satiety, definition.get("buff", {}))
		inventory.call("remove", id, 1)
		_show_hotbar_message("Ate %s." % str(db.call("item_name", id)))
		return

	# A tonic from the bar goes to the first standing party member -- the
	# creature the recall button would send out, which is who a player buffing
	# from the field means. The backpack's target picker stays the way to
	# choose somebody else.
	var tonic := definition.get("creature_buff", {}) as Dictionary
	if not tonic.is_empty():
		if _party == null or int(_party.call("size")) == 0:
			_show_hotbar_message("Nobody on the belt yet.")
			return
		var drinker: RefCounted = null
		for i in int(_party.call("size")):
			var member: RefCounted = _party.call("at", i)
			if member != null and not bool(member.get("fainted")):
				drinker = member
				break
		if drinker == null:
			_show_hotbar_message("Nobody standing to drink it.")
			return
		if not bool(drinker.call("apply_buff",
				str(tonic.get("id", id)), str(tonic.get("stat", "")),
				float(tonic.get("scale", 0.0)), float(tonic.get("duration_s", 0.0)))):
			_show_hotbar_message("That tonic isn't mixed right.")
			return
		inventory.call("remove", id, 1)
		_show_hotbar_message("%s drank the %s." % [
			str(drinker.call("label")), str(db.call("item_name", id))
		])
		return

	if heal <= 0.0 and revive_fraction <= 0.0:
		_show_hotbar_message("%s is not something you can use here." % str(db.call("item_name", id)))
		return

	if _party == null or int(_party.call("size")) == 0:
		_show_hotbar_message("Nobody on the belt yet.")
		return

	if revive_fraction > 0.0:
		# Auto-targets the first fainted party member -- there is no "worst"
		# among the fallen the way there is a most-hurt among the living, so
		# party order (the same order the belt/strip already shows) is the
		# tiebreak.
		var revive_target: RefCounted = null
		for i in int(_party.call("size")):
			var creature: RefCounted = _party.call("at", i)
			if creature != null and bool(creature.get("fainted")):
				revive_target = creature
				break

		if revive_target == null:
			_show_hotbar_message("Nobody needs reviving.")
			return

		revive_target.call("revive", revive_fraction)
		inventory.call("remove", id, 1)
		_show_hotbar_message("%s is back on its feet." % str(revive_target.call("label")))
		return

	var heal_target: RefCounted = null
	var worst_deficit := 0.0
	for i in int(_party.call("size")):
		var creature: RefCounted = _party.call("at", i)
		# A fainted creature is skipped, not targeted -- `heal()` now refuses
		# it anyway (D40), and a potion auto-aimed at the one creature it
		# cannot help would read as broken.
		if creature == null or bool(creature.get("fainted")):
			continue
		var deficit: float = float(creature.get("max_hp")) - float(creature.get("hp"))
		if deficit > worst_deficit:
			worst_deficit = deficit
			heal_target = creature

	if heal_target == null:
		_show_hotbar_message("Everybody's already at full health.")
		return

	var restored := float(heal_target.call("heal", heal))
	inventory.call("remove", id, 1)
	_show_hotbar_message("%s recovers %d." % [str(heal_target.call("label")), int(restored)])


## OF24 originally gave `build_open` (gamepad Start / keyboard B, opens the
## build menu without a trip through the pause menu's Build tab first) and
## `torch_place` (RT / keyboard P) the same job: read straight from the
## world and hand off to `build_menu.gd::_pick`'s own arming, `torch_place`
## planting a free ground torch directly. OW12 retired that ground torch
## (data/items/buildables.json), so `torch_place` now does the OTHER thing
## the owner asked for -- a fast draw/stow for the carried torch tool without
## hunting the hotbar for whichever slot it landed on (`_arm_torch_placement`
## below, despite the name it kept). Gated the same way `_read_hotbar_input`
## gates the hotbar: silent during a fight, and (new here) silent while the
## interaction arbiter is asleep -- a conversation, a naming prompt or a fade
## owns the screen exactly when that flag goes false
## (`sequence_director.gd::_refresh_lockout`), and a hammer opening over a
## dialogue box is the same class of bug OF23 fixed for a refused build pick.
## Neither reads while the build menu is already open -- `build_open` because
## a second press should not fight the first one's `open()`, `torch_place`
## because equipping UNDER an open menu makes no sense to the player either.
func _read_world_hotkeys() -> void:
	if Input.is_action_just_pressed(&"build_open"):
		# BUILD-FLOW promises that Start reopens the dedicated catalogue to
		# change pieces while a ghost remains armed. SequenceDirector correctly
		# disables InteractionArbiter during placement so X cannot both place and
		# talk/harvest, but the shared world-input gate treated that build-owned
		# lockout as a story modal and swallowed Start too. Allow only this one
		# catalogue action through when pending_build is the reason; combat and
		# an actual open input-owning panel still refuse it below.
		if not _world_input_allowed(true):
			return
		BUILD_MENU.get_or_make(get_tree()).call_deferred("open")
		return
	if not _world_input_allowed():
		return
	if _hammer_opens_the_catalogue():
		BUILD_MENU.get_or_make(get_tree()).call_deferred("open")
		return
	# HUD-INPUT-0903 (owner playtest 2026-09-03: "there should be a shortcut
	# button to map and to building"). A direct LT press opens the catalogue
	# without equipping the hammer first -- see project.godot's own comment on
	# `build_shortcut` for why LT is free to give it. Gated through the exact
	# same `_world_input_allowed()` call the hammer route above already passed
	# to reach this line, which is what keeps this from ever firing while a
	# panel owns input, a fight is running, or a build ghost is already armed
	# (the arbiter is disabled in all three, and `allow_armed_build` defaults
	# to false here) -- the same input_owner path, not a parallel one that
	# could disagree with it and soft-lock the world.
	if Input.is_action_just_pressed(&"build_shortcut") and not _build_menu_is_open():
		BUILD_MENU.get_or_make(get_tree()).call_deferred("open")
		return
	if Input.is_action_just_pressed(&"torch_place"):
		_arm_torch_placement()
		return
	# Swing whatever is in hand. Read here rather than in the player controller
	# so it inherits this function's gating for free: silent during a fight,
	# during a conversation, and while a build ghost is armed -- the three
	# states where the trainer does not have free run of the world.
	if Input.is_action_just_pressed(&"use_tool"):
		_swing_equipped_tool()


## Does the trainer have free run of the world this frame?
##
## OW10: the ONE answer both world-verb polls ask -- the hotbar
## (`_read_hotbar_input`) and the hammer/torch/tool hotkeys
## (`_read_world_hotkeys`). It used to be two functions with two different
## ideas of the answer: this one, and an inline pair inside the hotbar poll.
## They agreed about a fight and about the arbiter and disagreed about the
## build menu, which is the whole of the owner's report -- a d-pad press with
## the build menu open moved the grid selection AND spent a potion, because
## `hotbar_2`/`3`/`4` are bound to d-pad left/right/down (project.godot,
## joypad 13/14/12) and that menu deliberately does not pause the tree.
##
## Three things can hold input, and they are asked in cost order:
##
##   - a fight, unless the caller passes `allow_combat` -- which only the
##     hotbar does, and only since CONTROLLER-MAP. HD2 refused the hotbar in a
##     fight because `hotbar_2`/`3` shared the d-pad with D32's directional
##     switch actions, so a mid-fight switch also ate a potion. Those actions
##     are gone (one `party_cycle` press on LB replaced both), so the reason
##     for the refusal went with them and the owner's map wants the bar
##     reachable mid-fight
##   - the interaction arbiter being asleep, which is a conversation, a naming
##     prompt or a fade (`sequence_director.gd::_refresh_lockout`) -- reused
##     rather than re-derived, and the reason OF25 stopped a digit typed into a
##     name from spending a satchel slot
##   - any panel that has claimed input via `input_owner.gd`'s group, which is
##     how a non-pausing panel says so without anything here naming it
##
## A tree-pausing panel needs no entry: `PlaygroundHUD` is `PAUSABLE`, so it is
## already not running. No arbiter reachable (a stripped-down test or capture
## scene) reads as permissive, the same null-safe default `_combat_is_running()`
## already uses -- nothing there to be modal ABOUT.
func _world_input_allowed(allow_armed_build: bool = false, allow_combat: bool = false) -> bool:
	if _combat_is_running() and not allow_combat:
		return false
	if _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled")):
		var armed_build := allow_armed_build and _game != null \
				and str(_game.get("pending_build")) != ""
		if not armed_build:
			return false
	if INPUT_OWNER.current(get_tree()) != null:
		return false
	return true


## OW11: the build selector docks along the bottom of the screen, over the
## ground the hotbar block stands on, the same way Valheim's build bar takes
## the hotbar's place while you are building. So the hotbar and the context
## prompt stand down while it is open.
##
## This is a visibility swap, not a nudge. `build_menu.gd` is its own
## CanvasLayer and cannot see these rects (nor they its), so leaving both drawn
## does not produce two panels sharing a space — it produces the hotbar's slot
## chips reading THROUGH the selector's semi-transparent background, which is
## what the first captured frame of the docked menu showed: five numbered
## squares scattered along the thumbnail row like missing art.
##
## The hotbar is already inert while the selector is open, so nothing readable
## is being taken away — only the drawing of it.
##
## The same argument, unchanged, applies to every other panel that docks along
## this strip and owns input while it is up. A blind visual critic shown
## `shots/ui_glyphs/dialogue-panel.png` reported it: Grandpa's conversation box
## covers most of the hotbar and leaves slot 5 stranded to its right, with dim
## slot ghosts reading through the panel — "either hide the hotbar during
## dialogue or place the panel clear of it". That is OW11's own sentence about
## the build selector, one panel along.
##
## `input_owner.gd::GROUP` is the right question rather than a list of panel
## types: the contract is already "a panel that owns input while it is up joins
## GROUP", `dialogue_panel.gd` joins it on open, and
## `_exploration_legend_should_show()` above already stands the legend down on
## exactly this predicate. The hotbar is inert whenever something owns input,
## so again only the drawing of it is taken away.
##
## Also the one place both `_prompt_label.text` writers (`_ready()`'s seed and
## `_on_prompt_changed()`) get read back every frame, which is what makes this
## the right spot for the emptiness check below rather than a second one at
## each write site -- a write site added later would silently miss a
## duplicated check the way `input_owner.gd`'s header describes for the
## hotbar leak. A blind critic caught the failure of having no check at all:
## `_prompt_label` carries its own backing plate (`prompt_box` above) so that
## the contextual line reads over grass instead of floating bare -- but
## `fit_content` only collapses the TEXT to zero height when `text` is empty,
## not the plate's own `content_margin_top`/`bottom`, so an empty prompt still
## drew an unlabelled 800x12 pill bottom-centre of every frame with nothing to
## say. Gating on `not text.is_empty()` here removes the plate exactly when
## there is no line for it to hold, without touching `text` itself --
## `_exploration_legend_should_show()`'s recall check and the legend text
## builder both still read `_prompt_label.text` to know whether the prompt
## currently owns "Call out", and clearing the string instead of hiding the
## node would have broken both of those reads.
##
## The hotbar half of the swap also covers `_combat_is_running()` now, folded
## into the same `_hotbar_panel.visible` write rather than a second function
## racing this one for the same node -- whichever ran second would win and
## silently undo the other's answer. `combat_hud.gd` draws its own move grid
## and `Orbs N` readout (`_grid_panel`/`_orbs`) directly over this HUD's
## bottom-right corner on its own higher `UITokens.LAYER_COMBAT` CanvasLayer,
## a real overlap a blind critic caught (`shots/ui/10-combat-hud.png`:
## hotbar slot chips and "Orbs 10" compositing through the move grid).
## CONTROLLER-MAP still routes hotbar presses through the d-pad in a fight
## ("stays live... reachable mid-fight") -- that is `_read_hotbar_input()`'s
## own gate (`_world_input_allowed(false, true)`), unrelated to this node's
## `visible` flag, and PlaygroundHUD's `_process` keeps running through a
## fight (combat does not pause the tree) so the poll is unaffected by the
## panel going undrawn. Only the SAME thing OW11 already took away for the
## build menu -- the drawing -- goes with it here; the prompt is left out of
## this combat branch because it already carries its own combat dedup
## (`_prompt_belongs_to_combat()` blanks its text once the fight owns it),
## and the emptiness check just above already hides the plate for that case.
func _yield_bottom_to_build_menu() -> void:
	var yielding := _bottom_dock_should_yield()
	if _hotbar_panel != null:
		_hotbar_panel.visible = not yielding and not _combat_is_running()
	if _prompt_label != null:
		_prompt_label.visible = not yielding and not _prompt_label.text.is_empty()


## Shared with `_yield_left_stack_to_combat_hud()`'s own `_health_bar_cluster`
## write (HUD-BACKLOG-20) rather than inlined twice: the build menu draws
## over the hotbar/prompt's own strip, and any `INPUT_OWNER.GROUP` panel
## (dialogue, name prompt, starter picker) can draw a box that reaches into
## the same bottom band -- `smoke_dialogue_clears_the_world_hud.gd` measured
## the conversation box's own fixed bottom edge sitting inside the health
## bar's new lower-left position, the same collision this predicate already
## exists to prevent for the hotbar and the prompt.
func _bottom_dock_should_yield() -> bool:
	return _build_menu_is_open() or INPUT_OWNER.current(get_tree()) != null


func _build_menu_is_open() -> bool:
	for node: Node in get_tree().get_nodes_in_group(BUILD_MENU.GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return true
	return false


## CONTROLLER-MAP: "select it, press interact, you are in build mode".
##
## `build_open` lost its pad button — the owner's fourteen-button map has no
## room for one and the directive bans a chord — so the hammer became the way
## in: put it on the quick bar, press its slot to take it in hand, then press
## interact. Without this a controller could not reach the build catalogue at
## all, which is the one thing retiring `build_open`'s button must not cost.
##
## Deferred to the arbiter first. `interact` is talk/gather/chop/mine as well,
## and `interaction_arbiter.gd` is the one reader of it in the world — so a
## press that has a real target does that instead, and the hammer only claims
## the button when nothing is offering. Standing in front of Grandpa with a
## hammer in hand still talks to Grandpa.
##
## `winning_provider()` rather than the drawn prompt text: the prompt is a
## formatted string and carries no identity, which is what that accessor's own
## header says it exists for.
func _hammer_opens_the_catalogue() -> bool:
	if not Input.is_action_just_pressed(&"interact"):
		return false
	if _game == null or str(_game.get("equipped_tool")) != BUILD_TOOL:
		return false
	if _build_menu_is_open():
		return false
	# The question is whether the interact button is SPOKEN FOR, not whether any
	# provider is drawing a line. `encounter_director.gd::_creature_control_offer()`
	# falls back to a non-actionable status line -- "[RB] Call out <creature>" --
	# for any player who has a creature and is standing near nothing else, which
	# is most players most of the time. It advertises a different button and
	# `interaction_arbiter.gd::activate()` already refuses to fire it, so the
	# interact press is genuinely free; asking "is anything winning" made the
	# hammer lose the button to a line that was never going to consume it.
	#
	# Under CONTROLLER-MAP `build_open` has no pad button, so hammer + interact
	# is the ONLY pad route into build mode. This is the other half of the
	# owner's "building doesn't work" report: not a fight for the button, but a
	# forfeit to something that was not asking for it.
	if _arbiter != null and is_instance_valid(_arbiter) \
			and PROMPTS.is_actionable(_arbiter.call("winner")) \
			and not _winner_would_refuse_this_hand():
		return false
	return true


## Is the winning offer one that CANNOT fire with what is currently in hand?
##
## T5-CARE. The forfeit above is right for a real competing intent -- standing
## in front of Grandpa with a hammer still talks to Grandpa -- and wrong for an
## offer that is going to refuse the press anyway. Measured in the shipping
## world (`tools/_play_t5_freeplay.gd`):
##
##   standing on the clearing, arbiter winner <none>
##     -> one interact press opened Build
##   standing 1.5m from a deadwood node, arbiter winner Interactable
##     { "label": "Gather deadwood", "distance": 1.54, "actionable": true }
##     -> the same press did NOT open Build
##
## and the press did not gather either: `harvest_logic.gd::gather()` refuses
## outright when the visibly equipped tool is not the resource's
## `gathered_with`, so with the hammer out the player got the HUD line "Needs an
## Axe." and no catalogue. Both verbs lost. Under CONTROLLER-MAP hammer +
## interact is the ONLY pad route into build mode, and this world scatters
## 57,967 harvestable nodes -- the nearest is 5.7m from the centre of the
## opening's own authored build clearing. So the primary build verb was blocked
## by standing near a bush, chapter-wide, with nothing to tell the player why.
##
## Fixed HERE, in the hammer's own question, rather than by giving build mode a
## new binding: the owner's fourteen-button map has no room for one and the
## directive bans a chord, so a new binding cannot be spent on this. Fixed here
## rather than inside `interaction_arbiter.gd` too -- the arbiter's job is to
## decide which offer is nearest and drawable, and teaching it about equipped
## tools would put gathering rules inside the thing that arbitrates prompts for
## conversations, doors, beds and orbs alike. This is the one caller that needs
## the distinction, and it asks a narrow question: *would that offer refuse me?*
##
## Deliberately narrow in the other direction as well. A resource with no
## `gathered_with` (berries, `data/items/items.json`) gathers with anything,
## hammer included, so that offer is REAL and keeps the button -- the player
## pressing interact beside a berry bush wants the berries. Only a tool-gated
## resource whose tool is not the one in hand gives the press back to Build.
## And NOT solved by clearing scatter around build sites: that treats the
## symptom and thins the world.
func _winner_would_refuse_this_hand() -> bool:
	if _arbiter == null or not is_instance_valid(_arbiter):
		return false
	var provider: Object = _arbiter.call("winning_provider")
	if not (provider is Node) or not is_instance_valid(provider):
		return false
	# `harvest_node.gd` parents its own prompt, so the node offering the gather
	# is the Interactable's parent.
	var offering := (provider as Node).get_parent()
	if offering == null or not offering.has_method("resource_item"):
		return false
	var items: RefCounted = _game.get("items") if _game != null else null
	if items == null:
		return false
	var required := str(items.call("gathered_with", str(offering.call("resource_item"))))
	if required.is_empty():
		return false
	return required != str(_game.get("equipped_tool"))


## Swing the equipped tool at whatever is in front of the trainer.
##
## The refusal is deliberately spoken rather than silent. The 2026-08-15 blind
## playtest (PT-08) recorded the opposite pattern for the combat buttons --
## "silently inert outside an encounter... nothing teaches the player that
## these buttons need an encounter, so they read as broken" -- and an empty
## hand pressing swing is exactly that shape of mistake.
func _swing_equipped_tool() -> void:
	if _game == null:
		return
	var player := _game.call("find_player") as Node3D
	var hold: Node3D = player.get("tool_hold") if player != null else null
	if hold == null:
		return
	if str(_game.get("equipped_tool")).is_empty():
		_show_hotbar_message("Nothing in hand — press a tool on the bar first.")
		return
	hold.call("swing")


## OW12: the torch is a satchel item now (items.json's `torch`, `kind:
## "tool"`), equipped exactly the way `_use_hotbar_slot()` equips any other
## tool -- toggle off if it is already in hand, otherwise on. This function
## kept its old name and its old input (RT / keyboard P) rather than gaining
## a new hotkey action, since the button's whole point (a fast reach for the
## torch without hunting the hotbar) survives the swap from "arm a ground
## placement" to "equip the carried one" unchanged.
func _arm_torch_placement() -> void:
	if _game == null:
		return
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null or int(inventory.call("find_slot", "torch")) < 0:
		AUDIO_CUES.play(&"ui_error")
		_show_hotbar_message("No torch in the satchel.")
		return
	if str(_game.get("equipped_tool")) == "torch":
		_game.set("equipped_tool", "")
		AUDIO_CUES.play(&"ui_accept")
		_show_hotbar_message("Put the torch away.")
		return
	_game.set("equipped_tool", "torch")
	AUDIO_CUES.play(&"ui_accept")
	_show_hotbar_message("Torch in hand.")


## OF20. Polls `Game`'s one-shot toast queue (`take_pending_world_message()`)
## every frame -- the same read-and-clear contract `_update_region_banner()`
## already polls `map` through -- and surfaces it through the same message
## strip a hotbar-triggered refusal (repair, heal) already uses, rather than
## inventing a second banner for what is the same kind of event.
func _update_world_message() -> void:
	if _game == null:
		return
	var text := str(_game.call("take_pending_world_message"))
	if not text.is_empty():
		_show_hotbar_message(text)


func _show_hotbar_message(text: String) -> void:
	_hotbar_message.text = text
	_hotbar_message.visible = true
	_hotbar_message_until = Time.get_ticks_msec() / 1000.0 + HOTBAR_MESSAGE_SECONDS


func _fade_toward(control: Control, target: float, delta: float) -> void:
	var current: float = control.modulate.a
	var next: float = move_toward(current, target, FADE_SPEED * delta)
	control.modulate.a = next


## Fades this whole HUD toward `AIM_FADE_ALPHA` while a throw is being
## aimed, and back to fully opaque the moment it is not — `_root`, not any
## one block, so the creature block/vitals/hotbar/minimap dim together rather
## than each needing their own aim check layered onto their own idle-fade.
func _update_aim_fade(delta: float) -> void:
	var target := AIM_FADE_ALPHA if _combat_is_aiming() else 1.0
	_root.modulate.a = move_toward(_root.modulate.a, target, AIM_FADE_SPEED * delta)


func _debug_text() -> String:
	var lines: Array[String] = _perf_lines()
	if _debug_level != DEBUG_FULL:
		return "\n".join(lines)

	if _player != null:
		var speed: float = _player.call("ground_speed")
		var sprinting: bool = _player.call("is_sprinting")
		var pos: Vector3 = _player.global_position
		lines.append_array([
			"",
			"--- movement ---",
			"speed      %.2f m/s%s" % [speed, "   SPRINT" if sprinting else ""],
			"vertical   %+.2f m/s" % _player.velocity.y,
			"grounded   %s" % ("yes" if _player.is_on_floor() else "NO"),
			"position   %.0f, %.0f, %.0f" % [pos.x, pos.y, pos.z],
		])
		var vitals: RefCounted = _player.get("vitals")
		if vitals != null:
			lines.append_array([
				"stamina    %.0f / %.0f" % [vitals.stamina, vitals.max_stamina],
				"health     %.0f / %.0f" % [vitals.health, vitals.max_health],
				"worst landing  %.1f m/s  (%.0f damage)" % [_peak_fall, _last_damage],
			])
	lines.append_array(_input_diagnostics())
	return "\n".join(lines)


func _input_diagnostics() -> Array[String]:
	var lines: Array[String] = ["", "--- input ---"]

	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("controller  NONE DETECTED BY GODOT")
		lines.append("  the handheld is probably in desktop/mouse mode,")
		lines.append("  or the window does not have focus")
		_pad_connected_for = 0.0
		_max_raw_axis_seen = 0.0
	else:
		for device_id in pads:
			lines.append("controller  %d: %s" % [device_id, Input.get_joy_name(device_id)])
			if not Input.is_joy_known(device_id):
				lines.append("  NOT a standard mapping: buttons/axes may be wrong")

	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	lines.append("move  %+.2f %+.2f     look  %+.2f %+.2f" % [move.x, move.y, look.x, look.y])

	if not pads.is_empty():
		var device: int = pads[0]
		var lx: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var ly: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		var rx: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
		var ry: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		lines.append("raw axes  L %+.2f %+.2f   R %+.2f %+.2f" % [lx, ly, rx, ry])

		_max_raw_axis_seen = maxf(_max_raw_axis_seen, maxf(
			maxf(absf(lx), absf(ly)), maxf(absf(rx), absf(ry))))
		_pad_connected_for += READOUT_INTERVAL

		if _pad_connected_for >= STUCK_AXES_HINT_AFTER and _max_raw_axis_seen < STUCK_AXES_EPSILON:
			lines.append("  raw axes have not moved at all since the pad was seen.")
			lines.append("  On ROG Ally: Command Center -> Gamepad Mode (not Desktop")
			lines.append("  Mode) — desktop mode sends the sticks to Windows as a")
			lines.append("  mouse, not to the game as a controller.")

	lines.append("jump %s  sprint %s  interact %s" % [
		_held("jump"), _held("sprint"), _held("interact")
	])
	lines.append("")
	lines.append("pad: left stick move, right stick look, A jump, L3 sprint")
	lines.append("keyboard: WASD move, mouse look, Space jump, Shift sprint")
	return lines


func _held(action: String) -> String:
	return "[X]" if Input.is_action_pressed(action) else "[ ]"
