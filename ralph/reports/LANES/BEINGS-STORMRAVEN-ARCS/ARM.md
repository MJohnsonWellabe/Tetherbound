# BEINGS-STORMRAVEN-ARCS: branching white-violet arcs on the raven (F41#13, F36#74)

**Status: CPU-ready, NOT queued.**

| Row | Score (GPU High) | Defect, quoted |
|---|---|---|
| F41#13 electric creature finish | 6.91 on High and Medium | G-things-wardenring-f41-13-closeout, PARTIAL 3/3: the raven's speckles "read more like frost or sequins than lightning". Ask: "branching white-violet arcs along the raven's feathers". |
| F36#74 Stormraven poses | 6.37 | the same coat on the pose stage |

## Cause, and how it was confirmed
The shipped glow (`glow_read_r2`, from `below6_stormraven_night`) was picked texel by texel on Meshy's texture atlas, which is cut into hundreds of small islands. Any line drawn that way breaks at every island edge, so what shows on the body is scattered blobs: 7% of the texture lit, no connected line anywhere (sampled; the CPU base frame shows white flecks all over the plumage). That is the frost.

## Change
`data/config/creature_coat_flags.json` `beings_stormraven_arcs` (OFF; after the night coat in file order, so it wins when on). Same night albedo, finish, rim and emission energy as the shipped coat; new emission and a matching albedo copy made by `make_arcs.py` in this folder:
- the bolts are drawn in the model's own space, from each texel's model position and normal (`grade_vis_traits.anatomy_for`), so a bolt crosses UV seams unbroken;
- on each flank, one jagged main bolt runs from the shoulder back along the folded wing to the tip, with three forks;
- placed on a side-facing map of the mesh (the first try was off the body; the map fixed it);
- core white-violet, halo violet; bolt cores lightened a little in the albedo;
- the old flecks stay at a third of their strength, so the plumage keeps a faint sheen (removing them entirely left the bird flat black on CPU);
- the eye glow on the head is kept as it was.
Deterministic (seeded). No red: the test checks every lit texel is blue to white-violet.

## CPU before and after
`_sheet_cpu_base_top_arm_bottom.jpg` (hit 000, hit 050, faint 050, faint 100). Base: white flecks all over the body. Arm: one forked white bolt from shoulder to wing tip on the visible flank, faint sheen elsewhere. On CPU (LDR) the violet halo clips to white; on Forward+ it should show violet around a white core.

## By-eye line for the GPU lane
`stormraven-hit-000` / `stormwood__stormraven__idle`: a continuous forked bolt along the wing is visible. If the raven still shows only scattered flecks, hold.

## Risks
- "Overboard": the owner wants one subtle elemental trait. If judges call the bolt a decal or too bold, the next round is a thinner core (0.006) and lower emission, not removal.
- Interaction: BEINGS-STORMRAVEN-WINGS (pose) and this coat are independent and can both ship.

## Landing notes
Flag ON with `_why_on`; turn `test_flag_is_off_scoped_and_after_the_night_coat` into an ON pin. Add `beings_stormraven_arcs` to `LATER_COATS` in `tests/test_dark_value_lift_flags.gd` (it overrides the raven's value-lift albedo, as the night coat does) and run that file.
