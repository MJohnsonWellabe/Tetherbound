# F36#0 / F29#3 style-unification remakes: reference briefs (22 Oct)

GPU pass (tb/gpu-pass F36-0 VERDICT, all three judges): half the ON roster reads as realistic,
photo-textured, faceless meshes beside the stylised Ripplet / Aeriex / Riverdrake / Abyssal /
Veridian. Target style = those five: smooth sculpted colour masses (no photographic fur strands),
large readable eyes with a light catchlight, clean 2-3 colour blocking, mid-high value so the body
reads on dark ground, a friendly face. Identity (silhouette, palette family, signature parts) stays.

Shared prompt suffix (every brief):
"Stylised creature-adventure game concept, same render style as the attached Ripplet style
reference: smooth sculpted forms, clean painted colour blocks, no photographic fur or scale
texture, large expressive eyes with catchlights clearly visible from the front, readable face.
ONE full-body three-quarter view, neutral standing pose, all limbs separate and grounded, whole
silhouette in frame, plain light-grey background, even studio light, no text, no props, no
people, no red or oxblood anywhere. Riggable single body for image-to-3D."

Style reference for every brief: `assets/creatures/tetherbound/ripplet/reference/front.png`
(secondary: `riverdrake/reference/front.png`, `aeriex/reference/front.png`).

| # | Species | Identity reference (keep) | In-game height (vs 1.80 m trainer) | Brief |
|---|---|---|---|---|
| 1 | stormursa | `staticub/reference/front.png` (family) | 4.10 m | Adult storm bear grown from Staticub, NOT Staticub scaled: heavier shoulder hump, longer muzzle, small copper horn-like shoulder ridges, blue glass-like crystal studs along spine, Staticub's rounded ears and big blue eyes, warm brown fur with brighter chestnut belly, violet lightning seams painted as clean stripes. Reads ~1.3x Staticub's bulk at a glance. |
| 2 | staticub | `staticub/reference/front.png` | 3.25 m | Same cub: big round head, oversized blue eyes, pale muzzle, chestnut-brown fur in two clear tones, violet lightning stripes on shoulders. Cuter proportions than the adult (bigger head ratio). |
| 3 | tanglevolt | `tanglevolt/reference/front.png` | 3.40 m | Storm wolf: indigo/navy coat lifted to mid-value periwinkle, white-silver chest ruff and muzzle as clear blocks, glowing blue eyes enlarged, electric-blue lightning stripes; the coat must read lighter than near-black. |
| 4 | fulgocobra | `fulgocobra/reference/front.png` | 5.20 m | Storm cobra: hood raised, cream belly plates, body lifted from near-black to deep teal-charcoal with clear gold lightning cell pattern, large gold eyes with pupils, mouth closed. Hood held so the head sits above a 1.80 m person. |
| 5 | voltarach | `voltarach/reference/front.png` | 4.25 m | Storm spider: rounded, friendlier body, plated legs in warm bronze-gold with dark-slate (not black) carapace, the four blue eyes kept and enlarged in a clear face plate, chunky stylised legs. |
| 6 | galecrest | `galecrest/reference/three_quarter.png` | 3.50 m | Wind bird: wings folded, mid-value slate-blue plumage with white chest and cyan wingtips as clean blocks, crest feathers, large eyes, beak readable. Body must read on dark ground (no near-black). |
| 7 | mirejaw | `mirejaw/reference/front.png` | 2.80 m (raise head carriage so it reads above trainer's waist) | Swamp croc-axolotl: pink-coral frill kept (NOT red; coral/salmon), olive-teal mottled body as clean shapes, big friendly eyes, wide smiling jaw closed, legs that lift the body. |
| 8 | stormcapra | `stormcapra/reference/front.png` | 3.85 m | Storm ram: cream-white wool as a few large soft masses, dark slate legs and face, curling bronze horns, blue crystals on shoulders; face clearly visible outside the wool, big eyes. |
| 9 | tuskroot | `tuskroot/reference/front.png` | 3.60 m | Root boar: brown body with mossy-stone shell back, ivory tusks, big eyes, snout readable; shell colours as clean green/stone blocks. |

Process per asset (CLAUDE.md standing direction 1): reference drafted and inspected by this lane before
submission, scale check vs trainer, Meshy task ids recorded in `<species>/source/provenance.json`,
flag-off until its scene passes three-judge mapped Bar A >= 7.5 (CPU) / GPU confirmation.
