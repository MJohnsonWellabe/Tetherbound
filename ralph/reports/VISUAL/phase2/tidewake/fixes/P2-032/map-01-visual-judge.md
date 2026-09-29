# P2-032 / MAP-01 visual judgment

**Item verdict: PASS.** The after captures resolve the visible contradiction between the displayed realm heading and the apparent active realm tab in Water/Tidewake, Stormwood, and Cloudreach. A turquoise outline now identifies the tab that matches the displayed heading. The same cue correctly identifies Meadows in each supplied Meadows state and the realm again in each supplied return state.

This is a code-blind visual judgment of the supplied stills, using the interface, hierarchy, small-size readability, and artifact portions of `.claude/skills/visual-judge/SKILL.md`. No source, configuration, diffs, history, or other review reports were inspected. No production or engine files were edited.

## Evidence inspected

All 24 native images were inspected: the following four files in each of the six `raw-map-01-{before,after}-{water,stormwood,cloudreach}/` directories beside this report:

- `menu_map.jpg`
- `map_selected_meadows.jpg`
- `map_selected_water.jpg`, `map_selected_stormwood.jpg`, or `map_selected_cloudreach.jpg`, as appropriate
- `exploration_hud.jpg`

This covers all 18 map images and all six exploration HUD controls. All six corresponding `map-01-{before,after}-{water,stormwood,cloudreach}/contact_sheet_01.jpg` sheets were also inspected. Their four-across images are approximately 320 pixels wide per native 1920-pixel-wide frame, a more severe reduction than a 30% view. Native images support text and layout assessment; the compact sheets support comparative hierarchy and selection-cue assessment.

## Per-realm findings

| Realm | Before observation | After observation and verdict |
| --- | --- | --- |
| Water / Tidewake | In `raw-map-01-before-water/menu_map.jpg` and `map_selected_water.jpg`, the heading reads TIDEWAKE while Meadows has the brighter text and background. In `map_selected_meadows.jpg`, the heading reads THE MEADOWS but Tidewake is brighter. The tab treatment points toward the opposite state. | In `raw-map-01-after-water/menu_map.jpg` and `map_selected_water.jpg`, Tidewake has the turquoise outline and agrees with the heading and Whole Tidewake label. In `map_selected_meadows.jpg`, the outline moves to Meadows and agrees with THE MEADOWS / Whole Meadows. Both labels remain readable. **PASS.** |
| Stormwood | In `raw-map-01-before-stormwood/menu_map.jpg` and `map_selected_stormwood.jpg`, Meadows reads as more active despite THE STORMWOOD heading. The supplied Meadows state reverses the same mismatch. | In `raw-map-01-after-stormwood/menu_map.jpg` and `map_selected_stormwood.jpg`, The Stormwood is outlined and matches the heading. In `map_selected_meadows.jpg`, Meadows is outlined. The longer Stormwood label fits without truncation or intrusion into its neighbor. **PASS.** |
| Cloudreach | In `raw-map-01-before-cloudreach/menu_map.jpg` and `map_selected_cloudreach.jpg`, the bright Meadows tab competes with CLOUDREACH CLIFFS. In the Meadows state, Cloudreach Cliffs instead appears brighter. | In `raw-map-01-after-cloudreach/menu_map.jpg` and `map_selected_cloudreach.jpg`, Cloudreach Cliffs is outlined and matches the heading and Whole Cloudreach Cliffs label. In `map_selected_meadows.jpg`, Meadows is outlined. The longest realm label fits inside its outline. **PASS.** |

At native size, the after states retain bright text for both choices while adding a distinct boundary around the displayed choice. At compact size, the selected boundary remains visible in all three after sheets and changes sides in the Meadows image. Fine control text is too small for comfortable reading at that sheet scale; the result is a hierarchy check, not evidence of full small-screen text usability.

## Adjacent UI and existing defects

The before/after map pairs show no new visible displacement or clipping of the top navigation, realm heading, survey label, canvas frame, map labels, or control hints. All three paired exploration HUD controls preserve their placement and visible text; no new HUD regression is apparent from those pairs.

The following defects remain visible before and after and are separate from this item's PASS:

1. **Map area is dominated by empty panels and a narrow black central strip.** This is visible in every `menu_map.jpg` and selected-state image; the Meadows states make the strip especially narrow. Region/destination headings occupy much more visual space than the sparse map content. The selected tab fix does not establish map readability or geographic usefulness.
2. **Long map labels are poorly accommodated.** The Cloudreach realm frames display `CLOUDREACH GATE / LOWER` while the exploration HUD displays `Cloudreach Gate / Lower Cliffs`. The map text ends without the final word or an explanatory ellipsis in both phases. Its large lettering also overwhelms the small map marker.
3. **Footer layout lacks breathing room.** In all map frames, the comma/period switch hint breaks between `[Comma/` and `[Period]`, making one key instruction span two lines. The low-contrast menu footer sits against the bottom image edge, with no comfortable safe-area margin. These same defects appear in both phases.

## Scope limits

The named explicit-selection captures show visually coherent resulting states in both directions. Stills cannot independently prove which input produced a state, clickability, keyboard/controller focus behavior, transition correctness, persistence, or runtime responsiveness. No such behavioral claim is included in the verdict.

This review concerns the displayed-region selection issue and adjacent UI only. The exploration frames are regression controls, not a chapter-wide art survey. Palworld UI is expressly outside the rubric's comparison scope. The key-art and Palworld chapter/world bar questions are therefore **not assessed** here; no chapter bar verdict or reference-gap ranking is fabricated from these UI-focused frames. All requested final image evidence was available and inspected.
