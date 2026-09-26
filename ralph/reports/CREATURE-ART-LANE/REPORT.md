# Creature & hero art lane (X04)

Scope: creature, trainer/cast and named hero-subject art (ROADMAP §3 X04;
ACCEPTANCE §4; ART_DIRECTION §5, §7, §8; CREATURES; visual cards M3, C2, S2, T2).

## Status

- **Meshy is gated on owner art.** The owner said in this session that Meshy is
  not to be used without art from them. No Meshy task has been submitted by
  this lane. The only task on record is still the rejected Terrapup retexture,
  `01a0cfcd-84ea-7243-a723-1c1b205739de` (MEADOWS-VISUAL-PASS).
- **Handover.** `ralph/meshy-terrapup` holds one unmerged commit
  (`bd4fc0ac`, the STATE note for round 3 and the rejected pilot). It has no
  in-progress asset work, so nothing needs integrating.

## Ranked subjects

Ranked by player exposure (lane brief), then re-ranked by blind-judge findings
(MEADOWS-VISUAL-PASS rounds 1–3 and R7, STATE §4).

| # | Subject | Judge finding | Owner reference on file |
|---|---|---|---|
| 1 | Terrapup (starter) | Front meets the bar (R3). Rear shell reads as mottled; the body reads as clay with white splotches that look generated (R7). | `docs/art/reference/01_Ground_Starter_Terrapup.png`: full sheet with front, side, back and 3/4 views, mantle detail and palette. |
| 2 | Ripplet (starter) | Not captured by any judge round yet. | `02_Water_Starter_Ripplet.png` |
| 3 | Galewisp (starter) | Not captured by any judge round yet. | `03_Air_Starter_Galewisp.png` |
| 4 | Bramblebun (redesign) | Goes brown and dissolves against the dirt in the world; ears blown out in the studio shot (R3). | `creature-expansion-2026-08-30/06_Bramblebun_redesign.png`, `wild/02_Meadows_Wild_Ground_Sheet.png` |
| 5 | Mudsnout / Tuskroot | Low-contrast texture in fight frames; flat blocking (R2, R3). | `wild/01`, `wild/02` |
| 6 | Trailpup, Meadowhart, Burrowback, the other Meadows wild species | Flat colour blocking roster-wide. Burrowback keeps its named ~1.30:1 exception and dark armour. | `wild/01`–`05`, `08_Meadows_Roster_Art_Reference.png`, `05`–`07` roster boards |
| 7 | Trainer (Lyra/Kael/Sera player choices) | Dark legs (historical, unverified); stiff pose in tour frames (R7). | `04`, `22`–`25` |
| 8 | Grandpa, rival trainer, captains A/B, Warden | No current judge finding. The captain's accessory is missing (ledger). | `09`, `10`, `16`, `npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png` |
| 9 | Veridian stag | Deer-like alpha is the clearest style outlier (R1). | `11_Ground_Legendary_Reference.png` |
| 10 | Abyssal (Tidewake) Guardian | Distant silhouette risk (STATE §4). | `35_Abyssal_Guardian_Board.png`; isolated input `abyssal_guardian/reference/meshy_candidate_01.png` |
| 11 | Stormheart | Has no species row and no art. `stormwood_encounters.json` stages `fulgocobra` at scale 1.8 in the `alpha_stormheart` colourway as a placeholder. | **None.** |

## Reference-art needs (for the owner)

1. **Isolated views for Meshy input.** Every owner reference on file is a
   multi-panel sheet. Image-to-3D needs clean single-subject views: front,
   side, back and 3/4 on a plain background, with no text and no overlapping
   panels. The owner decides whether cropping the turnaround panels from the
   owner's own sheets counts as owner art, or whether fresh isolated images
   are needed. The starter sheets and the Meadows NPC board already carry
   separated turnaround panels.
2. **Terrapup's shell colour conflicts between sources.** The owner sheet
   (`01`) shows a brown/cream badger with **grey stone plates and moss
   tufts**. Species data comments and the approved regrade call it a "mint
   shell", and that regrade shipped. The judge's rear-shell complaint is
   exactly this region. The owner needs to decide which is canon before any
   Terrapup candidate is made.
3. **Stormheart.** There is no species, board or model, only a Fulgocobra
   placeholder. Creating it is a roster/data decision outside this lane
   (no new species without the owner), and it needs owner art if it is to be
   built.
4. **Oxblood versus purple for Team Tether.** The NPC board dresses grunts,
   officers, captains and the Warden in black with **Tether purple**.
   CLAUDE.md and ART_DIRECTION reserve **oxblood/red** for Team Tether. Any
   cast rework needs the owner to say which applies. This lane will not
   repaint either way without that decision.
5. **Scale is not taken from the sheets.** Several sheets show pals under
   1 m (Terrapup ~0.45 m shoulder). The hard rule and live data win: every
   creature stays above the 1.80 m trainer. Sheets are used for identity only.

## Work that needs no new art

These stay within owned paths and the existing pipeline, pending owner
direction on the items above:

- Before-captures and a code-blind baseline judge of the three starters at
  gameplay distance (idle/walk/run/attack/turn, real fight), plus the scale
  ladder and clipping check.
- Checking the trainer's dark legs against the source texture versus the
  material, before any art change.

## Provenance

No new asset, reference or Meshy task in this lane yet. Every future task ID
is recorded here. The API key is never recorded.
