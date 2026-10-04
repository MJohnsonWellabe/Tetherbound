# F21#5 matched A/B judge r1

The judge was a code-blind sub-agent working from pixels only. The A/B labels were shuffled per shot; the key is in `ab-key.json`.

**Limit:** the image tool hit request limits, so only 31 of the 56 frames loaded. The confidence is therefore medium to low.

| Shot | Preferred | Decoded | Confidence |
|---|---|---|---|
| quick | A | after | medium |
| charged | B | after | medium-low |
| crit | A | after | medium |
| incoming | B | after | medium-low |

**Raw result: after preferred in 4 of 4 shots.** The deciding evidence was mostly the damage number: present after and absent before. The crit read gold "✦" with a larger burst; the charged hit read as "43" against "10".

Defects the judge raised in the preferred (after) frames:
1. The numbers are tiny, about 25 px at 1080p, and the gold crit has low contrast on grass.
2. The impact burst disc covers the small target.
3. No knockback displacement is visible. This is expected from stills: hitstop holds the bodies, and the 0.3 m light knockback is small at fight distance.
4. Incoming numbers look the same as outgoing ones (by spec, own-creature numbers are 0.85× in the same palette).
5. The crit barely outranks a quick hit apart from its glyph.
6. The stagger banner sits far from the target.

**Action:** defect 1 was fixed (base 36 px, floor 28, outline 4). The after set was re-captured as r2 and re-judged from contact sheets so every frame is seen. Defects 2 and 5 belong to F25 effect craft (`scripts/vfx/**` with the shared hit spark owned by the VFX lane), and the spec values for 4 and 5 are COMBAT §11. They are recorded here for those owners.
