# Creature disposition — 2026-09-10

Status: twenty-nine retained production improvements, one rejected face experiment,
two asset-level gaps isolated, and the Skyrill replacement generated, cleaned,
textured, locally rigged, animated, installed, and validated in Godot.

## Retained

- **Skyrill replacement.** The irreconcilable broad-winged dragon has been
  replaced by the approved compact cliff lizard: four separated weight-bearing
  legs, one continuous orange-blue dorsal sail, a complete balancing tail, slate
  and cream hide, and large readable amber eyes. One preview passed the structural
  gate; its refine result passed four-angle visual review. The production path then
  cleaned the accepted preview from 54,876 to 28,000 triangles, retextured it
  against selected reference candidate 03, locally rigged 15 bones with zero
  unweighted vertices, authored six gameplay clips, and installed the resulting
  27,996-triangle GLB. Extreme pose renders showed no collapsing shoulders,
  candy-wrapper neck or tail-root failure. A Godot Compatibility four-angle pass
  caught and removed the obsolete winged-dragon UV overlays before final acceptance.

- **Skyrill surface hierarchy.** The former rule forced nearly every chromatic
  texel to one cyan and erased the installed atlas's blue/coral/cream anatomy.
  The ordinary texture now preserves the source regions, caps only excessive
  saturation, and lifts/deepens the forward head plane. A fresh production-body
  orientation capture has a readable eye, muzzle, cream underside and warm wing
  edge. This improves the installed asset but does not make its broad winged
  silhouette match the owner's compact sail-backed cliff-lizard board.
- **Torrentoad palette and attack contact.** The ordinary texture now preserves
  the source's slate-blue wet back, cream throat and restrained warm digits rather
  than flattening the body into orange/teal. The attack GLB's constant two-key root
  translation was replaced by a calibrated source-frame grounding curve. The
  matched low pose changed from `minimum_world_y=-0.8884697`, `4965` vertices below
  floor to `minimum_world_y=0.0154347`, `0` below floor. A 25-point full-trajectory
  native Compatibility sweep has zero below-floor vertices at every sample.
- **Ironwood road flock.** Band 4's order-4055 density flock overlapped the later
  order-4916 road-visibility pair. The before frame put four full-size Galecrest
  1.6–4.8 m from the trainer and framed ten creatures. The complete four-body
  flock now occupies a ridge pocket 30 m perpendicular to the trail while the
  deliberate two-body sightline stays authored. The matched production capture
  has no body closer than 18.9 m and frames six rather than ten creatures; the
  road and trainer remain fully visible.
- **Voltarach ordinary palette.** The broad ordinary rules had replaced the
  installed source's charcoal shell, warm amber edge planes and blue facial nodes
  with one hot-magenta mass—the exact Stormwood creature the combined blind review
  singled out. Ordinary wildlife now preserves and restrains those source regions,
  matching the owner board's material hierarchy. The separately authored alpha is
  unchanged and remains storm-indigo/cyan. A fresh Compatibility production-body
  render confirms the ordinary body is charcoal/amber/blue rather than magenta,
  with all three facial nodes readable.
- **Pebbik ordinary palette.** Its installed source already matches the owner
  board's warm tan/cream body, blue feather tips and dark facial features. The
  former broad rules erased those regions into neon yellow and purple. Ordinary
  Pebbik now preserves the source hierarchy with a restrained chroma ceiling. A
  fresh Compatibility production-body render reads as the board's small cliff
  pika again, including both eyes, cream muzzle/chest and blue ear/tail accents.
- **Stormcapra ordinary palette.** The global azure treatment had collapsed its
  coat, armour and horns into one saturated blue body. Its installed source already
  matches the board's white/charcoal ram with sparse blue crystal accents, so the
  ordinary runtime texture now preserves those authored regions.
- **Aeriex ordinary palette.** The former violet/cyan treatment turned the entire
  aerial creature magenta and hid its face. Its source-authored cream body, teal
  flight feathers and coral tips are restored and visible in the Compatibility
  lineup.
- **Breezetail ordinary palette.** The prior coral rule erased natural fur values
  and facial contrast. Its brown-and-cream body, blue feather accents and dark eyes
  are restored from the installed source atlas.
- **Tempestwing ordinary palette.** The prior fluorescent violet treatment erased
  the insect's segmented body and translucent wing hierarchy. Its installed deep
  blue, pale-blue and gold material regions now survive the runtime grade.
- **Solmane ordinary palette.** The former solar remap pushed the complete winged
  lion to near-neon yellow. Its source-authored cream/gold fur, readable face and
  restrained dark-teal feather edges are restored.
- **Craghorn ordinary palette.** The installed white/grey fleece and dark horns
  already matched the owner board. Source preservation removes the orange speckle
  and cyan-neutral shifts introduced by the former global rules.
- **Ribbonray ordinary palette.** The former flat-magenta treatment hid the small
  blue/cream face and collapsed the layered purple, blue and warm underplanes. All
  authored ribbon regions and the black eye now survive the runtime grade.
- **Cloudfang ordinary palette.** The installed source already matched the board's
  white and pale-blue wolf, including grey shadow planes and bright blue eyes.
  Source preservation keeps that value hierarchy instead of over-saturating the
  accent fur cobalt.
- **Cliffspike ordinary palette.** The former amber/blue remap flattened the entire
  porcupine into bright gold. Its authored tan/cream fur, cool quill shadows and
  paired black eyes are restored.
- **Stormwood ordinary roster recovery (nine species).** Voltwig, Glimmermoth,
  Stormbrush, Staticub, Tanglevolt, Stormraven, Thundertunnel and Fulgocobra now
  preserve the board-aligned anatomical regions already present in their installed
  source atlases instead of collapsing into orange, pink, yellow, cyan or purple
  masses. Mosshock is the bounded exception: its installed atlas had usable newt
  anatomy and a cream belly but lava-red growth, so only the authored red/gold
  growth regions are repainted moss/yellow-green while its neutral structure and
  amber eyes remain intact. Two fresh Compatibility lineups confirm distinct faces,
  coat/feather/scale hierarchy and board-readable silhouettes across all ten
  installed Stormwood species, including the previously repaired Voltarach.
- **Water ordinary roster completion (five species).** Cannonback, Aquaryn,
  Tidecoil, Riverdrake and Abyssal Guardian now preserve their installed
  board-aligned blue/slate, cream, coral and ochre anatomical regions instead of
  collapsing into broad cyan, violet, magenta or orange treatments. Together with
  the six previously recovered Water bodies, fresh Compatibility lineups now show
  readable faces and distinct shell, scale, fin, throat and gill materials across
  all eleven installed Water species. Abyssal Guardian's material mismatch is
  repaired; its overwhelming presentation envelope remains a separate asset/layout
  gap.

Evidence is intentionally ignored under
`.artifacts/torrentoad-face-contact-0909/captures/` and
`.artifacts/broad-visual-0910/creature-orientation01/shots/`.

## Rejected

An anatomy-mapped Torrentoad eye treatment tried dark paired sockets plus amber
centres. The inner predicate covered nothing and the outer predicate rendered as
vertical cheek stripes, not eyes. It was removed before the retained texture was
generated. The final texture contains only the source-preserving grade and broad
forward-face separation.

## What is actually still wrong

1. **Torrentoad's eyes are not readable frontal forms on the installed mesh.** Its
   palette and floor contact can be repaired without replacement, but the owner
   board's large amber eyes are not available as clean visible geometry/UV islands.
   The rejected paint test establishes that another broad anatomical mask would be
   fabrication, not recovery of authored detail.
2. **Abyssal Guardian has an extreme presentation envelope.** The source-preserving
   grade removes its flat purple/pink treatment and restores navy/slate scales with
   a pale throat, but its neck and fins extend far outside a five-body 1600 px lineup.
   This is not a palette problem and must not be solved by violating the retained
   legendary scale rule. It needs a legendary-specific camera/layout contract or a
   replacement asset whose authored proportions remain immense without occluding
   the rest of the scene.
3. **Exploration crowding is an envelope/admission mismatch beyond the repaired
   Ironwood hotspot.** Spawn admission and
   creature spacing use gameplay capsule radii while several rendered bodies extend
   6–11 m. The previously tested shared road ribbon is not a solution: peaceful
   creatures rotate their complete envelope toward the trainer inside the 9 m notice
   range. The safe next implementation is habitat/site-specific presentation
   clearance or a notice-turn constraint, followed by the four-biome route capture;
   do not shrink the roster or repeat the failed shared ribbon.

## Next execution boundary

The owner's direction now explicitly authorizes Meshy for creature assets that need
replacement. Skyrill is complete. Torrentoad is next because the installed mesh has
no recoverable frontal eye forms; its retained grounded attack curve must survive the
replacement. Abyssal Guardian follows if its replacement preview preserves legendary
scale while reducing the current vertical and lateral presentation envelope. Both now
have clean selected single-subject references and provenance beside their turnarounds.

## Skyrill reference round

The owner subsequently directed this lane to figure out the creatures. Skyrill
remains the first replacement target: its 12.6 m rest-wing span is both the largest
route-presentation envelope among the ordinary problem bodies and an irreconcilable
silhouette mismatch against the owner's compact cliff-lizard board.

Three clean, single-subject image-to-3D candidates live under
`assets/creatures/tetherbound/skyrill/reference/`. Candidate 03 is selected for
the next generator step because it best preserves the board's compact quadruped,
large amber eye, restrained blue/cream hide, orange-blue tapered sail, and fully
visible riggable limbs/tail. Candidate 01 is the fallback; candidate 02 is held for
its oversized fan and glossy toy finish. Full prompts and provenance are recorded
beside the images. This round generated reference art only and spent zero Meshy
credits.

Candidate 03 produced the retained replacement described above. The key was supplied
ephemerally through a secure prompt and is not recorded in the repository or manifest.
The generator's own thumbnail was not used as acceptance evidence; Godot and Blender
renders established the installed result.
