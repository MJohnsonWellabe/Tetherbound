# Ironwood Grove R7 Meshy — code-blind production review (2026-09-11)

## Verdict: POLISH

R7 is a clear visual promotion over the R6 FAIL. The replacement tree finally creates
an unmistakable ancient-tree silhouette, a massive grounded root plate and a readable
scale jump from trainer and ordinary trees to named-location hero. It does not reach
PASS because the ordinary arrival is still substantially occluded, the workyard still
lacks a credible production process, creature clutter competes with the reveal, and
close/night frames expose angular foliage and inconsistent material exposure.

The manifest is internally usable: it reports eight 1280x720 production Meadows frames,
four ordinary player stands at 18–55 m, matched day/night pairs, no failures and no
prop/creature/progression injection. All eight named PNGs are present. This evidence
supports an in-world verdict rather than an isolated asset verdict.

## Frame-specific evidence

### 01 road arrival — day/night

- **Day:** The blue-grey crown now separates from the Meadows trees and the hero is
  identifiable at 55 m, an important improvement over R6's generic copse read. However,
  the lower trunk and root plate are almost entirely masked by a large dark creature,
  a pale creature, and bright foreground saplings. The hero therefore reads first as a
  distant unusual crown, not as a colossal rooted ancient tree. The loose line of
  creatures across the road remains a competing focal band.
- **Night:** The crown silhouette survives against the sky, but the trunk, roots and
  workyard collapse into the dark middle distance. Creature bodies and pale accents
  remain as readable as the landmark. The player is exposed correctly; the destination
  is not.

Arrival hero-read is improved to POLISH, not closed to PASS.

### 02 southwest hero — day/night

- **Day:** This is the strongest distant proof. The broad canopy, fused trunk bundle
  and pale spreading roots form a distinct, old-growth silhouette at 47.5 m. Scale is
  credible beside the trainer and surrounding trees. Foreground saplings still cut
  through the lower crown and trunk, while creatures are scattered across both flanks.
- **Night:** The moon and sky separate the full crown, and enough root mass remains to
  hold the tree to the terrain. This is the best night location read. The upper canopy
  becomes a nearly uniform dark-blue cap, losing internal branch/crown organization,
  but it does not disappear as in R6.

### 03 inside old growth — day/night

- **Day:** At 18 m, the replacement is convincingly monumental. Multiple heavy trunks,
  hollows, lateral boughs and buttress roots establish an ancient identity that the R6
  cylinder-and-stick construction lacked. The root plate appears seated on the ground,
  with no obvious whole-model float or catastrophic import break. The remaining defects
  become obvious here: pale bark/root values look bleached against the saturated green
  world; foliage consists of many sharp folded shards; several bright-green ordinary
  trees occlude the trunk; and a large dark creature fills the lower-left foreground.
- **Night:** The silhouette remains large, but most bark planes and root hollows compress
  into navy-black. Thin root edges catch isolated pale highlights. The foliage surface
  becomes noisy rather than coherently tiered, and the foreground creature merges into
  the dark ground.

### 04 ironwood workyard — day/night

- **Day:** The hero now gives this view a strong named-location backdrop and believable
  scale. Its rightward crown/bough silhouette is particularly good. The workyard itself
  remains the blocker identified in R6: one oversized rectangular timber rail dominates,
  with a small bench and indistinct tool shapes but no clear raw-log staging, cutting or
  splitting operation, debris/chips, finished stock, or circulation path. Green, white
  and pink glow effects compete with the supposed work process.
- **Night:** The trainer, scaffold and hero are all visible, which is useful. But the
  tree flips from the dark treatment in frame 03 to a very bright blue-white treatment
  here; roots and trunk look icy/bleached and foliage facets sparkle individually. This
  reads as local exposure/material inconsistency rather than restrained authored fill.
  The work-process story remains absent.

## Acceptance ledger

| Category | R7 grade | Evidence |
|---|---|---|
| Ordinary arrival hero read | **POLISH** | Distinct crown at 55 m, but trunk/root mass is hidden by saplings and creatures. |
| Ancient silhouette and scale | **PASS-quality in 02/03/04** | Broad crown, fused trunks, hollows and massive roots clearly exceed ordinary trees. |
| Material/style integration | **POLISH** | Palette distinguishes hero, but pale bark is bleached and night response varies sharply by angle. |
| Roots/grounding | **POLISH+** | Large root plate visibly contacts terrain; small tips remain shard-like. |
| Foliage quality | **POLISH** | Coherent macro crown, visibly angular folded fragments at close range and under night highlights. |
| Workyard process | **FAIL-quality subsystem** | Scaffold/bench visible, but no readable material-to-output craft sequence. |
| Creature clutter | **FAIL-quality composition** | Large dark and pale creatures repeatedly cross the arrival/hero axis and one dominates frame 03. |
| Night exposure | **POLISH** | Hero silhouette survives, but 03 crushes bark dark while 04 blows it pale. |

## Visible import/topology concerns

No frame shows a missing trunk section, exploded vertex cloud, whole-model float, or
obvious catastrophic import corruption. The asset is visually intact enough for a
POLISH candidate. The crown does show many thin, disconnected-looking triangular leaf
fragments and stray spikes, especially in frames 03 and 04. Several root tips also end
as flat angular shards. These are consistent with unclean generated topology and could
produce shimmer, culling pops or unstable LOD transitions even though the still frames
do not prove those runtime failures.

## Blockers to PASS

1. Clear the ordinary approach axis enough to reveal the hero's lower trunk and root
   mass; retain a small number of scale trees, but remove the bright sapling screen.
2. Keep large roaming creatures out of the central reveal/workyard composition, or
   stage them to the sides so they demonstrate scale without blocking the landmark.
3. Replace the generic rail read with an explicit work chain: raw timber, installed
   cutting/shaping station, chips/debris, finished stock and a readable path threshold.
4. Prune or consolidate the most obvious leaf/root shards and verify a stable gameplay
   LOD from the 47–55 m approach.
5. Balance local night fill so the trunk/root planes remain visible without turning
   blue-white in the workyard view.

R7 should enter the ledger as **POLISH**. The hero-asset gap is materially closed; the
remaining PASS blockers are now primarily arrival composition, workyard authorship,
creature staging and night/material cleanup.
