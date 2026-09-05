# Blind visual judgement — dialogue portraits

Images seen: `_sheet_ingame_conversations.png`, `_sheet_portraits.png`,
`assets/ui/portraits/trainer.png`, `assets/ui/portraits/grandpa.png`, and
`docs/reference/`. Nothing else. No score given.

## A. Does the portrait read as the person standing there?

**Frame 2 (Oskar) — yes, unambiguously.** Bowl-cut dark hair with a straight
fringe, cream short-sleeve collared shirt with the button placket, and a dark
brown leather vest carrying two scrolled embossed motifs on the chest — all
three read identically on the model and on the plate. The plate is a pixel match
for sheet cell r5c6 (32px diff 3.0). This is the pair to keep.

**Frame 1 (Halda) — yes as a body match, no as an identity.** Chin-length brown
bob, olive short-sleeve hooded jacket, cream tunic under it, and the same gold
collar clasp all match the woman in the scene, and she is clearly not the player
(the player is at frame right in a blue jacket with a white fur collar and
backpack). But that plate is one of **seven identical cells** on the contact
sheet (r2c1, r3c2, r3c6, r4c6, r5c3, r5c5, r6c1; pairwise 32px diff 0.10–2.77 —
below the noise floor). Matching it back is ambiguous: the box says "Halda" over
a face that is also six other people's face. Two villagers in one conversation
chain would show the same portrait.

One cross-cutting artefact: a hard-edged pale grey wedge sits on Halda's cheek in
the plate — and the same wedge is on the **player's** cheek in the frame-1
close-up, and on Oskar's jaw in r5c6. It is on the source heads, not just the
plates, so re-baking will not remove it.

## B. Do they sit in the same UI family as trainer.png / grandpa.png?

**Ground: exact match, no complaint.** Every new plate is flat neutral
#F2F2F2 (242,242,242), pixel std < 0.6 — same value and same flatness as the two
shipping plates (std 0.9 / 1.5). No gradient, no tint, no alpha halo. Nothing to
fix here.

**Head size in frame: the real mismatch.** Skull width across the top of the
head: trainer 154 px, grandpa 153 px. New plates: r2c1 122, r5c6 129, r3c5 142,
r3c3 147. So the typical villager head is ~20% narrower and sits with more chest
and both shoulders inside frame — it reads as taken a step further back. On its
own that is a low-grade irritation, visible only when a villager plate follows
trainer/grandpa in the same conversation.
The outliers are not low-grade: **r6c3 (78 px), r4c3 (79), r1c5 (80), r6c4 (98),
r4c4 (103), r1c3/r2c4/r4c2 (106)** are *half* the trainer's head width. r2c3 is
worst — the farmer is framed from mid-thigh with a full pitchfork, head ~23% of
plate height; at a 130px dialogue plate his face would be ~30px. A player would
read those as a different asset entirely.

**Value range.** trainer meanL 93, grandpa 143, both with <0.7% blown pixels.
New plates run meanL 46 (r2c5) to 163 (r4c1), and r4c1 blows out 8.97% of its
pixels, r3c3 4.29%. The dark tail (r2c5 46, r4c3 50, r2c4 51, r1c5/r4c2 55) tops
out at L=229 — no highlight anywhere, so at 64px they are featureless dark
blobs. Both tails are outside the bar the two shipping plates set. Would bother a
player: moderately on the dark ones, a lot on the blown ones.

**Rendering style.** trainer/grandpa are painted: shaped hair masses with clean
edges, controlled skin highlight, a catchlight in the eye. Most new plates are 3D
captures under a paint filter: fuzzy alpha on hair, features smeared rather than
drawn, eyes as flat black holes with no catchlight (r1c2, r3c4). On the better
cells (r5c6, r3c5, r6c3, r6c4, r2c1) this reads as "slightly softer" and passes.
On r6c2, r3c3, r5c4, r5c1, r1c6 it reads as broken art.

Minor: trainer/grandpa leave ~5px of ground below the shoulders; every new plate
runs content to the bottom edge. Nobody will notice.

## C. Contact sheet — count, confusions, defects

**Distinct characters: 26 of 34 filled cells.** Two clusters are duplicates, not
variants: the olive-jacket bob woman ×7 (r2c1, r3c2, r3c6, r4c6, r5c3, r5c5,
r6c1) and the masked purple bandit ×3 (r1c3, r2c4, r4c2). r6c5 and r6c6 are
empty grey.

Hard to tell apart at thumbnail size, though not identical: r2c5 / r3c1 / r2c6 /
r4c4 (all near-black Team Tether uniforms, meanL 46–57, no highlight — one dark
blob each); r1c2 / r3c4 (cap-wearing kids in warm jackets); r1c5 / r4c3 (dark
armoured men); r5c2 / r6c2 (same wide-brim-hat silhouette).

Visible defects, worst first:
- **r6c2** — face melted; mouth and moustache are a brown smear, forehead and
  nose blown white; hat brim sliced by the right plate edge.
- **r3c3** — the whole face is a flat near-white slab; only eyebrows and two
  black eye-smudges survive; nose and mouth nearly gone.
- **r5c4** — chin/mouth is a brown crusty blob; blown cheeks; hair **clipped by
  the top edge** (content starts at y=3); detached hair chunks top-left.
- **r5c1** — blotchy grey-white face with red-rimmed sockets; reads as a corpse
  rather than a design choice.
- **r1c6** — left half of the face is flat pale yellow-white, eyes reduced to two
  dark slashes.
- **r1c4** — large flat blown area over cheek and nose; eyepatch reads as a
  smear; spiky detached hair wisps at top-left; body sliced at the right edge.
- **r4c1** — 8.97% blown; cheeks are flat pink discs on white (doll decal);
  hard-edged grey wedge on the jaw; floating hair strands top-left.
- **r4c3** — his left eye is a blank white hole; mouth a dark smear; shoulder
  sliced at the right edge.
- **r2c2** — mismatched eyes (one black blob, one half-lidded smear); nose is a
  dark blob; hair carries hard triangular polygon cuts.
- **r3c1** — asymmetric eyes; hair is a flat slab with a hard notch cut in it.
- **r1c2** — eyes are hollow black ovals with no catchlight; a straight-line seam
  crosses the chin/neck.
- **r2c3** — pitchfork tines clipped by the top edge (y=3); framing outlier.
- **r4c5** — white hair wisps float detached off the skull; dark smear inside the
  glasses lens; body sliced at right edge.
- **r3c5**, **r2c6** — a triangular hair splinter / detached lock at the right of
  the head.
- **r2c5**, **r2c6** — a stray pink-mauve sphere hangs at the chest on both.
- Grey cheek/jaw wedge (the shared source-head artefact): all seven olive-jacket
  cells, plus r5c6, r3c5, r4c1.
- Content running off the right plate edge: r1c1, r1c4, r1c5, r1c6, r4c3, r4c5,
  r5c2 (quiver), r6c2, r6c3.

## D. Other things wrong in the two in-game frames

**Portrait-related**
1. The same UI element is drawn in two different greys. Frame 1's plate
   background is uniformly (222,222,222); frame 2's is (242,242,242). The whole
   frame-1 plate is multiplied by ~0.917 — brighten it by 242/222 and it matches
   the sheet cell to a diff of 3.7. A player going villager-to-villager sees a
   grey card then a white card. Cheap to fix, and worth it.
2. The plate is a hard-cornered white square inside a rounded, near-black
   dialogue panel, and at 130px it is the brightest object on the screen — it
   pulls the eye off the line of text it is supposed to attribute.
3. The 20% head-size deficit from B shows here: there is visible empty grey above
   the hair and down both sides, so the face lands smaller than the panel implies.

**World / scene, not the portraits**
1. **Frame 2: a grey block floats unsupported in mid-air** beside Oskar's head,
   with more grey blobs hanging near the horizon behind it. Loudest bug in either
   frame.
2. **Frame 1: the quest tracker sits on top of a world signboard**, covering its
   title so only "…VER MEADOW" survives. UI is eating a readable world object.
3. **Both frames: the camera does not stage the conversation.** The player is at
   extreme close range, back to us, bisected by the right screen edge and by the
   dialogue box; the villager is small and off to the left. The two speakers are
   never in a shared frame.
4. **Frame 2: the hero tree's canopy** is a chaotic mix of flat pure-green and
   near-black spiky cards with black gaps through it — it reads as broken foliage
   alpha, and it is the worst silhouette in either frame against the keyart's
   shaped oak canopies.
5. Ground cover is thin and evenly scattered next to `palworld-02` /
   `palworld-03` — identical white flower sprites at regular spacing, a hard-edged
   brown dirt patch under the tree in frame 2, and grass billboards that stop at a
   dead-straight line across the bottom of frame 1.
6. Villager faces in-world are washed pale with a heavy dark shadow band across
   the eyes (frame 1), so the model's face reads worse than its own portrait.
7. The bottom-left barrel in frame 1 is half-buried and tilted against the ground
   plane.
