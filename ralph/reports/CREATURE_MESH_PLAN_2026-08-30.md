# Creature Mesh Generation Plan — Meadows Creature Expansion, 2026-08-30

Prepared by the T1-CREATURE-MESH lane for the coordinator to execute. This
lane holds no Meshy API key and generated nothing; everything below is
crops + `views.json` entries + prompts, already committed on
`ralph/T1-CREATURE-MESH`, ready for `tools/art_pipeline/meshy.py generate`.

Balance at brief time: **3410 credits**. Observed real cost per task
(`tools/art_pipeline/meshy.py`'s own measured figures, not the pricing page):
**20 credits/preview candidate, 40 credits/refine candidate.**

Order, per the pipeline's own cost discipline (`meshy.py` docstring §COST):
cheap preview first to sanity-check form, then a moderate refine batch only
on species whose preview form is worth pursuing, then further spend
(`texture`, a second refine batch) only on the chosen winner. **Bramblebun
first** — it is the common species, the owner's own stated priority, and the
one where the resolution concern below matters most.

## Read this before spending anything

**The reference is smaller than this pipeline's established comfort zone.**
`views.json`'s own `_comment_output` says source figures on the existing
sheets run 180–450px per view and calls that "the real fidelity ceiling."
Measured off the master sheet for these five: **every front/side/back figure
is roughly 70–190px on its longest side**, i.e. at or below the bottom of
that range, not within it. Bramblebun's own turnaround figures measure
~90–100px wide. This is not disqualifying — Grandpa and the Warden shipped
usable meshes from ~150px crops with the prompt carrying more of the
load — but it means the **prompt text is carrying more weight than usual**
for all five, and Bramblebun most of all, since it is the one where a soft
result is least acceptable. If the preview round comes back generic or
melted, the fix is almost certainly not another prompt rewrite — the source
resolution is what it is — and the honest next step is telling the owner the
board's per-creature panels are too small to drive a confident final asset,
per the brief's own instruction to say so before spending further credits.

**Four views per creature, not three.** Front/side/back share one scale
(the pipeline's usual convention) plus a fourth, genuinely new for a
creature on this pipeline: **`top`**, a real orthographic top-down drawing
this sheet carries that no prior creature sheet has had. Cropped at its own
scale via `extra_boxes`, the same mechanism the wild sheets use for their
hero panel. `meshy.py`'s `VIEWS` list already included `top` (added for
props); no code change was needed to make it count as a real input for
these five. See the handover for why `three_quarter` was rejected instead —
short version: the sheet's only 3/4-ish view is a crouched action hero pose
that fights the standing turnaround's neutral pose, which is worse than the
scale mismatch `three_quarter` usually risks.

## Per-creature plan

For every entry: `--candidates 3 --tier preview` first (60 credits, under
the 60-credit `--budget` default, no `--yes` needed). Review the three
candidates (render + `inspect_glb.py`/turntable per the pipeline's usual
next step) against the "good result" column before spending anything else.

### 1. Bramblebun (redesign) — PRIORITY 1

```
tools/art_pipeline/meshy.py generate bramblebun_redesign --candidates 3 --tier preview
```
Cost: 60 credits. **Not keyed `bramblebun`** — the existing
`assets/creatures/tetherbound/bramblebun/reference/` and its shipped mesh
stay in place until this candidate is judged better; this is a parallel
replacement candidate, never an edit in place.

Prompt (from `SPECIES_PROMPTS["bramblebun_redesign"]`, `tools/art_pipeline/meshy.py`):
> meadow guardian rabbit creature, larger and more substantial than an
> ordinary warren rabbit, roughly 1.0m body length. OVERSIZED DRAMATIC EARS
> with woody branch-like antler tips and thorny vine wrapping partway up
> each ear, LIVING BRAMBLE AND LEAF GROWTH across the back and shoulders
> with small reddish thorn accents, a bramble-tufted tail. Earth-brown and
> cream fur body with muted leaf-green mossy patches over the back, dark
> expressive eyes, sturdy round body and strong hind legs, cream chest and
> face markings. Silhouette first: broad readable forms with detail
> concentrated only in the ears, tail, bramble growths and face markings —
> NOT an unreadable pile of foliage, the rabbit body must still read
> clearly beneath the plant growth.

Good result: silhouette reads as "rabbit" at a glance before any bramble
detail resolves (the owner brief's own bar); antler-branch ear tips and the
bramble tail survive as distinct features, not fused into a single leafy
blob; body mass visibly larger than the current shipped Bramblebun. Reject
if: the plant growth swallows the rabbit's own silhouette (the brief's named
failure mode), or the antler-ear tips melt into plain rabbit ears (the
generator dropping a capitalized-but-once-mentioned feature is this
pipeline's most common failure per Terrapup/Grandpa's own round-2 notes).

If preview form is promising: 3 refine-tier candidates next (120 credits) —
`--candidates 3 --tier refine` — since this is the one species where a
mediocre result is not acceptable per the owner's own framing. Then
`texture` against `front.png` for the winner if refine's own texture pass
under-delivers on the mossy/thorny surface language (2K, ~30 credits).

### 2. Sparkit

```
tools/art_pipeline/meshy.py generate sparkit --candidates 3 --tier preview
```
Cost: 60 credits.

Prompt:
> small electric fox-coyote creature, stormlands wanderer, roughly 0.6m
> body length. OVERSIZED READABLE EARS with dark tufted tips, LONG TAIL
> ENDING IN A JAGGED LIGHTNING-BOLT SHAPE, a spiky charged fur ridge
> running from crown to tail base. Cream and pale lightning-gold body with
> graphite-black markings across the face, back and legs, bright blue
> eyes, black nose, slender alert fox-like build. Keep the fur simple and
> broad — NO tiny whisker detail, NO over-complicated fur clumps — so the
> ears, tail and body mass all read clearly at a glance.

Good result: ears read as the dominant silhouette feature (the sheet's own
"large ears" note); tail resolves as a distinct lightning-bolt wedge rather
than a generic bushy or tapered tail. `sparkit` is the one species where
`NEGATIVE_CREATURE`'s stock ban on "fox proportions" was removed
(`DROP_FOR_SPECIES`) because fox-coyote proportions are this creature's own
canon, not drift — do not re-add that ban if retuning the negative prompt
later.

If promising: 2 refine candidates (80 credits).

### 3. Cindercub

```
tools/art_pipeline/meshy.py generate cindercub --candidates 3 --tier preview
```
Cost: 60 credits.

Prompt:
> small fire-ground cub creature, compact and sturdy, roughly 1.4m body
> length. GLOWING EMBER TAIL TUFT like a small contained flame at the tip,
> dark soot-black paws and lower legs, a few subtle glowing ember cracks
> across the shoulders and back. Terracotta-rust fur body with a cream face
> blaze and chest, bright orange eyes, black nose, short rounded muzzle,
> compact stocky cub build with a strong readable head shape. Keep the fire
> language simple — glowing tail tuft and a few ember cracks only, NOT
> flames covering the whole body — contained and believable rather than an
> inferno.

Good result: reads as a solid, compact cub with a few contained
glowing/ember accents — not a creature wrapped head-to-tail in flame
texture (the sheet's own explicit warning). Tail tuft and ember cracks
should be visible as distinct sculpted or shaded features, not lost in
general fur noise.

If promising: 2 refine candidates (80 credits).

### 4. Shadelet

```
tools/art_pipeline/meshy.py generate shadelet --candidates 3 --tier preview
```
Cost: 60 credits.

Prompt:
> medium dark lizard creature, nocturnal wanderer, roughly 1.6m body
> length, NOT a tiny gecko. LONG CURLING TAIL that coils into a tight
> spiral, a ridge of low broad spikes running from crown down the spine
> and tail, OVERSIZED AMBER-GOLD EYES with an alert forward gaze.
> Midnight-purple and shadow-blue scaled body with a subtle violet sheen,
> broad flat readable head, sturdy four-legged lizard stance, dark clawed
> feet. Keep scale patterns broad and simple — large readable plates rather
> than fine texture — body sized like a monitor lizard, never small or
> thin.

Good result: a medium, substantial-looking lizard, not a palm-sized gecko —
this is the owner brief's single named risk for this species. Tail coils
into a clean spiral rather than trailing straight. One thing to check on
the actual mesh, not assumed from the crop: the reference's own `side.png`
draws the tail with a visible gap in its coil (confirmed against the
master sheet, not a cropping defect — see the handover) — if the generator
reproduces that gap as a literal break in the mesh rather than a tail
curling out of view behind itself, that candidate should be rejected and
re-rolled, since a physically disconnected tail is not something a texture
pass fixes.

If promising: 2 refine candidates (80 credits).

### 5. Frostclaw

```
tools/art_pipeline/meshy.py generate frostclaw --candidates 3 --tier preview
```
Cost: 60 credits.

Prompt:
> medium-large ice predator feline, lynx and snow-leopard influence,
> roughly 2.0m body length, NOT an ordinary real-world cat. TUFTED
> BLACK-TIPPED EARS, OVERSIZED PAWS with pale blue ice-crystal claws, a few
> BROAD ICE-CRYSTAL ACCENTS at the shoulders and cheeks, frosted whisker
> shapes framing the muzzle. Pale gray-white fur with slate-gray spotted
> markings, bright icy-blue eyes, black nose, sturdy predator build with a
> long thick tail. Use only a few large readable icy forms — NOT hundreds
> of small crystals — and keep it reading as a Tetherbound creature rather
> than a photoreal wildcat.

Good result: a few large, clearly-sculpted ice-crystal accents at
shoulders/cheeks, not a fine crystalline texture wash (the sheet's own
warning, and the brief's explicit "not an ordinary real-world cat with
blue fur"). Ears and paws should read as oversized/tufted rather than a
generic short-hair cat silhouette.

If promising: 2 refine candidates (80 credits).

## Running total

| Stage | Cost |
|---|---|
| Preview, all five (3 candidates each) | 300 |
| Bramblebun refine ×3 | 120 |
| Sparkit/Cindercub/Shadelet/Frostclaw refine ×2 each | 320 |
| **Subtotal if every species proceeds to refine** | **740** |
| Balance after, of 3410 | **~2670** |

Texture passes on chosen winners (2K, ~30 credits each, per the pipeline's
established `retexture` step) are not included above since they depend on
which candidate wins each round; budget roughly 150 more if all five need
one. This leaves comfortable headroom under 3410 even before accounting for
species that stop at preview because the resolution concern above proves
out as a real blocker rather than a formality.

## What NOT to do

Do not run all five straight to `--tier refine` without a preview pass —
that would be spending 40-credit candidates to answer a question the
20-credit tier answers just as well (does the FORM read at all), which is
exactly the discipline `meshy.py`'s own docstring exists to enforce. Do not
generate a `three_quarter` view for any of these five; none of them have
one, and using the per-creature sheet's hero pose in its place was
evaluated and rejected — see the handover.
