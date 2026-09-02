# Terrapup — production report

The pipeline proof required by `TETHERBOUND_3D_ART_PIPELINE.md` §29. Terrapup
is the first character produced from the owner's reference pack, and this
records what was actually done — including the failures — so the next
eighteen characters inherit a process rather than a legend.

## Summary

| | |
|---|---|
| Reference | `docs/art/reference/01_Ground_Starter_Terrapup.png` |
| Generator | Meshy multi-image-to-3D (REST, see D11), 2 rounds × 3 preview candidates |
| Inputs | The four turnaround crops from `crop_views.py`, 1024², shared scale |
| Texturing | Meshy retexture: cleaned mesh + text style prompt + the 3/4 concept crop as `image_style_url`, PBR, 2k |
| Cleanup | `cleanup_mesh.py`: 55k tri soup → 28k manifold (weld 6,840 dupes, voxel remesh, decimate) |
| Mesh fixes | Two rounds of critique-driven edits (`fix_terrapup_e.py`, `fix2_terrapup.py`) |
| Rig | `rig_quadruped.py` — own 15-bone skeleton, bone-heat weights, **0 unweighted of 14,051 verts** (Meshy rigging is humanoid-only) |
| Animations | 6 procedural clips (`animate_quadruped.py`): idle, walk, run, attack, hit, faint |
| Shipped file | `assets/pals/tetherbound/terrapup/models/pal_terrapup_lod0.glb`, 9.5 MB, 28,080 tris, 1 material, 2k PBR |
| In-game | `data/pals/species.json` → `terrapup`; fitted to its 1.2 m collider by `pal_body._fit()`; 107 tests + all smoke suites green |
| Credits spent | ~90 of 1,100 (6 previews ≈ 60, 1 retexture ≈ 30) |

## The loop, round by round

Every round: generate/edit → `inspect_glb.py` + `turntable.py` →
`compare_sheet.py` → a **blind critic** (a fresh agent shown only renders and
concept, told nothing about what changed or which candidate was hoped for) →
act on its top findings. Verdicts quoted verbatim; sheets in
`docs/art/production/`.

**Round 1 — three candidates, all rejected.** Critic ranked b best ("skull
crest spikes, cheek ruff spikes... recognizably the same attitude as the
drawing", "by a wide margin the best mantle") but its forepaws were "barely
distinguishable from the hind paws" — and the concept makes oversized digging
paws the creature's functional signature. a: "a cute bear cub with decals,
not Terrapup." c: invented a beaver-paddle tail. Decision per §26:
regenerate, with the prompt stating the missed features harder (ENORMOUS
forepaws, short legs, LOW stone-capped tail) and the negative list gaining
each specific round-1 invention.

**Round 2 — candidate e wins.** Fresh critic, shown b beside the three new:
e "wins on the three things texture cannot fake: lowest tank-like mass,
correct blunt big-head face proportion, and the only genuinely plate-like
mantle." b dropped to third — "texturing will not hide a wrong skull shape."
e's faults ruled "(a) fixable by mesh editing": paws still under-scale, tail
raised ~45°, crest weak. Applied as weighted volume edits: paws 1.6×
(z-scaled from the ground so bigger feet stay planted), tail −50°.

**Texture pass.** Retexture aimed at the drawing itself (3/4 crop as style
image). Critic: "close-but-not-yet — the palette, stripe, eyes and stone back
all land," with a mesh-level list: paws still ~half the concept's relative
width, no silhouette-breaking ruff ("smooth toy bear cub"), muzzle drifted
"raccoon/red panda", tail high with "a rounded grey pebble." Fixes applied to
the *textured* mesh — UVs ride with vertices, so the mostly-right texture
survived: paws +1.35× (≈2.1× cumulative), muzzle 1.25× wider and blunted,
tail −18° and 1.3× thicker, and a noise-displacement ruff experiment in a
collar band.

**In-engine gate, round 1.** Critic on the Godot validation frames:
"close-but-not-yet", top findings **against the renderer, not the asset** —
"chocolate-to-ginger colour shift... looks like a tonemapping mismatch rather
than a texture problem, because the turntable of the same asset is correct";
"shiny toy plastic" fur under the game sun; stone mantle invisible because
every frame was dead front-on. Fixes: `validate_asset.gd` now uses the real
scene's numbers (sun 1.25, exposure 1.05, white 6.0 — copied from
`world_look.gd`/`art.json`, not approximated) and two off-axis cameras;
the GLB's material got metallic 0, specular 0.25, roughness floored at 0.75
(§12: no wet plastic fur).

**In-engine gate, round 2 — PASS.** Fresh critic, new frames, told nothing:
"**yes** — a player would identify them as the same designed character
without hesitation... This is a pass, not a courtesy pass. The remaining
issues are drift, not misidentification." Its one iterate-now item — fur
still a touch warm, and the mantle plates rendering pale because the first
grade's white-mask had also matched light-grey stone — became the final
grade retune (fur saturation boost removed, a dedicated stone branch that
darkens neutral greys toward the sheet's ROCK swatch, cream blend gated to
warm whites only). Its two defer items — the face's badger banding versus
the concept's softer mask, and the rump's invented cream chevrons — are
recorded under known imperfections, per its own judgement that they are
"polish-tier gain" for "remodel-tier cost" on one of nineteen characters.

## Topology and technical

| | generated | shipped |
|---|---|---|
| Triangles | 54,454 | 28,080 |
| Duplicate vertices | 6,840 | 0 (welded) |
| Manifold | no | yes (voxel remesh) |
| Materials | 0 (untextured) | 1, PBR 2k (base colour/metallic-roughness/normal) |
| Armature | none | 15 bones, 0 unweighted |
| Clips | none | 6, named for `species.json`'s role map |

Deformation checked with `pose_test.py` (stride, look, crouch, tail flick):
no tearing, no collapse. GLB imports into Godot 4.7 with no material or
skeleton errors; `smoke_art` confirms it fits its collider (1.20 m model on
1.20 m collider).

## Known imperfections, honestly

- **The crest and ruff are soft.** The concept's spiky skull crest survives
  only as texture. The displacement-ruff experiment neither fixed nor hurt
  it. A real fix is sculpting — deferred, recorded.
- **The clips are procedural.** Legible (walk reads as walk; the attack is a
  species-informed rear-up-and-slam with real anticipation), but they are
  cycles, not character animation. First candidates for replacement.
- **The rear texture** carries a cream halo ring around the tail stone that
  the concept does not have.
- **Colour still renders a shade lighter in-engine** than the concept's
  chocolate, after the tonemap fix; the remaining gap is ambient fill in the
  meadow scene, shared by every asset in it.
- **Topology is decimated triangles**, not retopologised quads. Fine at
  gameplay distance and for these clips; a hero close-up pass would want
  §11's manual edge-flow work at the shoulders.
- **Eyes go dark at combat distance** (any eye does at 6 m). If the teal read
  matters in fights, the fix is a slight emissive on the iris — a decision
  for the owner, not taken unilaterally.

## Owner review

**The final box of §18 — "Owner would willingly use the asset in the actual
game" — is yours.** The evidence: `docs/art/production/` sheets, the
validation frames in `shots/validation/`, and the creature standing in the
meadow in the survey. If the answer is no, say which finding above (or which
new one) is the reason, and the loop continues from there — the whole chain
from crops to installed GLB reruns in about fifteen minutes plus generation
time.

## What §30 gets

The process that actually worked, for the skill: crop → 3 cheap candidates →
blind-critique → regenerate once with the critique's words in the prompt →
pick → volume-edit the winner per critique → clean → retexture against the
concept crop → volume-edit again on the textured mesh → own rig → procedural
clips → engine validation with the real scene's rendering → blind gate.
The speculative branches this replaces: Meshy MCP, Meshy rigging, Meshy
animation library, and any hope that prompt text alone controls proportions.
