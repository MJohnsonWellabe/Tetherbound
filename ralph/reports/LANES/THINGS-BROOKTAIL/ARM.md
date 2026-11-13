# THINGS-BROOKTAIL: fewer, smaller aqua spots (F36#36 close-out)

**Row.** F36#36 Brooktail: High 7.69, Medium 7.03 (`G-medium-ashtusk-brooktail-ruler.md`). 3/3: "the aqua spots are too many and too large, and read as a leopard pattern". Owner pick: deep-river black otter with glowing aqua spots.

**Cause.** The spots are lit by the model's own glow map (`arc_emission.png`, 2.65% of the atlas lit), with matching aqua paint in the coat.

**Change** (flag `creature_coat_flags.json things_brooktail_spots_1112`, OFF). Two derived textures, same mask: the glow map with small spots removed and the rest shrunk (lit area 2.65% -> 1.88%), and the lifted coat with the removed spots painted back to the otter's own dark fur. Identity, silhouette and colours are kept. No new art, no Meshy.

**CPU** (`_sheet_spots_off_vs_on_cpu.jpg`; top main, bottom arm; standing and faint end): the scatter of small dots is gone and the large ovals are smaller; the head keeps its eye markings. Two stronger settings were tried and dropped (one left a single spot).

**Not in this arm.** The near-black head with no rim (3/3) and the spikes at faint end (2/3). The rim is a stage or light change; a cool rim on the pose stage would help several dark species.

**Check.** `texture_import_policy.py --check` passes (both new textures on the VRAM-compressed path). No script errors in the capture.

**Ask.** Brooktail, `capture_f36_poses.gd --whole-body --context --roles=hit,faint`, base vs arm, High then Medium.
