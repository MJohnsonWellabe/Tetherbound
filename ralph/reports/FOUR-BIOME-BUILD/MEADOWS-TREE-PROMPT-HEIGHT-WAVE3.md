# Exact Meadows tree prompt reachability — Wave 3

The fresh campaign stopped at wood 31/42 after 632.274 seconds in parent session
31669. Its selected tree at (45.44735, -0.188587, -62.50097) must remain the target;
the fix does not skip it or enlarge the 2.6 m interaction radius.

The shipped `data/scatter/playground/region_0_-1.bin` identifies this as `trees`
order 320, `CommonTree_2.gltf`, yaw 4.35441541671753, scale 1.59811049938202.
The production layer collision radius is 0.435 times scale = 0.695178 m; its
production cylinder height is 4 times scale = 6.392442 m. The actual Player's
capsule radius is 0.4 m. Canonical heightfield at the tree is -0.18858828246593,
matching the baked placement height. The ground slopes down on its south side:
z+1 m is -0.453991; z+4 m is -1.024195.

Old `vegetation._spawn_harvest_point` raised the prompt by `1 + scale`, or
2.5981105 m here. On level ground, its 2.6 m sphere would permit only about
0.099 m horizontal separation from the trunk axis, already inside the trunk.
This is a source explanation of the observed side's failure, not a proof that
every uphill direction is unreachable.

## Decisive native control

`tools/_probe_scatter_tree_prompt_height.gd` reads that exact baked row, calls the
actual production harvest-spawn and collider factory, and uses the actual Player,
InteractionArbiter and Interactable. A 14-by-14 m local triangle collider samples
the canonical heightfield at 1 m spacing. It does not load Terrain3D, the campaign
world, a save, or a player party. The initial player position is a disclosed
synthetic diagnostic fixture. Ordinary stick input walks toward the selected tree
until first actual trunk contact within 180 frames, then ordinary Interact is
observed. The harvest callback is disconnected only in this diagnostic, so it
tests real arbiter activation without submitting a synthetic ledger claim.

Old source control: grounded actual player (45.45166, -0.465704, -61.39447),
actual trunk touched, prompt (45.44735, 2.409523, -62.50097), distance **3.080792**,
radius **2.6**, no own offer, no arbiter offer, physical activation false,
zero unsticks, exit **1**. No errors or warnings.

Changed source control: the identical grounded player position and trunk contact,
prompt (45.44735, 1.211413, -62.50097), distance **2.009246**, radius **2.6**,
own and winning Chop offer actionable, physical activation true, zero unsticks,
exit **0**. No errors or warnings.

Logs are retained separately under `%TEMP%`:

- `wave3-exact-tree-first-contact-old-{console,engine}.log`
- `wave3-exact-tree-first-contact-fixed-{console,engine}.log`

Both native controls use distinct isolated APPDATA profiles. No full world was
launched and neither control claims wood payout or an earned campaign milestone.
The native floor is an analytic local mesh, not the full shipped Terrain3D
collision/residency stack; the corrected fresh campaign still needs validation.

## Change and focused regression

Wood harvest prompts use the already established human-height 1.4 m default,
factored as `vegetation_harvest_point.HUMAN_PROMPT_HEIGHT`. The wood call site
selects that height independently of visual tree scale. Unprobed stone prompts
retain their prior scale rule. No radius, collision, terrain, ledger, tool, yield,
save, retry or smoke budget changes.

`tests/test_vegetation_human_prompt_height.gd` exercises the actual spawn method
on the exact shipped row, verifies old versus current contact reach, keeps the
wood amount/identity and radius, checks human-height invariance across scales,
and pins the existing stone anchor behavior. Final focused result:
**3 tests / 16 assertions / 0 failures**, no errors/warnings. Logs:
`%TEMP%/wave3-vegetation-prompt-final-focus-{console,engine}.log`.

After the native positive control, the final source was narrowed from all harvest
items to wood only; the exercised tree's height/geometry is identical. It was not
rerun unchanged to manufacture additional passes. The probe's success gate now
also explicitly requires its already observed trunk contact and zero unsticks.

## Earlier diagnostic failures retained

The first metadata command had one GDScript type-inference parse error; its r2
metadata log is clean. `wave3-exact-tree-old-*` used the wrong triangle winding,
leaving the player ungrounded and producing runaway-velocity warnings. This was a
probe construction failure, not evidence against production. Correcting winding
produced a clean grounded floor (`old-r2`), but a fixed-direction stick passed the
tree. The next measurement steered at the tree but sampled only the endpoint
after ordinary collision sidestepping (`contact-old`); it showed no offer but was
not accepted as contact proof. The final probe stops on first actual tree contact
and produced the old/new control pair above. Those earlier logs remain intact;
none was counted as runtime campaign evidence.

Fresh3588_2512 has now physically harvested the previously failing exact tree
(45.44735,-0.188587,-62.50097): actual wood31→34 with ordinary input, at player
(44.89627,-0.393814,-61.37055). This is live confirmation beyond the native
first-contact probe. Run remains active gathering the remaining campsite cost;
this receipt does not claim paid camp, full completion or terminal clean logs.
