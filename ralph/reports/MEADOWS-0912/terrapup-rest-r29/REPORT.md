# Independent Terrapup rest verdict — R29

**Verdict: reject R29. Do not promote this pose or tune it by changing the
`-78°` roll a few degrees.** Both frames are judgeable, and both show the same
structural failure. The torso-contact receipt (`0.050m`) is true only for the
sampled torso band; it does not describe the complete creature. The full pose is
`-1.901m` below the accepted surface interval and `1.330` standing-heights tall.

## What the pose visibly does

In `a_review_side_prone-front-day`, Terrapup reads as a twisted upright body, not
a side-prone sleeper. One rear paw rises above the head, the near forepaw becomes
the dominant support, the chest and head remain high, and the body spills beyond
the circular bed. In `a_review_side_prone-three-quarter-day`, the open eye and
square muzzle face the viewer while one paw projects toward camera and another
limb stands nearly vertical. The silhouette says “contorted alert creature” or
“failed ragdoll,” never weight resting through a flank.

R29 therefore regresses the useful R28 evidence. R28's best height ratio was
`1.112`; applying a whole-model `Z=-78°` roll plus `72–104°` lower-leg rotations
increased it to `1.330`. The model roll rotated an already unsuitable faint-pose
limb envelope into the vertical axis, while torso-only grounding allowed the
outlying paws to penetrate far below the bed. More roll cannot repair that
relationship.

## Smallest credible R30

Make R30 a structural ablation, not another twelve-bone guess:

```json
{
  "clip_role": "faint",
  "model_rotation_deg": [0.0, 0.0, 0.0],
  "model_position_offset": [0.0, 0.0, 0.0],
  "bones": {
    "pelvis": {"position_offset": [0.00, -0.34, -0.34], "rotation_deg": [0.0, 0.0, 16.0]},
    "spine":  {"position_offset": [0.00, -0.10, -0.20], "rotation_deg": [8.0, 0.0, 12.0]},
    "neck":   {"position_offset": [0.10, -0.08, -0.34], "rotation_deg": [20.0, -32.0, -18.0]},
    "head":   {"position_offset": [0.10, -0.08, -0.10], "rotation_deg": [12.0, -48.0, -26.0]}
  }
}
```

Omit all eight leg overrides for the first R30 render: inherit the completed
faint clip's legs and remove the four extreme `72/92/84/104°` distal folds and
all leg translations together. This isolates whether the torso/cheek recipe is
viable without the paw explosion. Ground from the complete visible bounds to a
target low point of `-0.10m`, and require **both** full-pose ground offset inside
`[-0.22,+0.08]` and torso lower-quartile offset `<=0.20m`; a translation must not
be accepted when those conditions cannot coexist.

Only after that base is low and coherent should one limb pair be tucked per
candidate. Keep upper-leg translation magnitude at `<=0.05m` on every axis and
added joint rotations at `<=35°`; do not restore R29's large lower-leg values.
Require a per-region bounds receipt for torso, each leg, head and tail so the
part causing height or penetration is named. If the no-leg-override base still
exceeds `0.95`, stop: the completed faint clip is not a usable substrate, and R30
should switch to an idle-frame skeletal pose rather than continue offset tuning.

Advance only if both views show a continuous low back/flank, all paws relaxed
beside or partly under the body, the muzzle/eye turned into the bed, and the
existing strict `<=0.82` height gate passes.

## Largest gaps from the references

1. The creature silhouette is anatomically incoherent in both frames; the
   references use compact, instantly readable character poses.
2. The pose has no believable weight/contact: torso sampling says contact while
   visible limbs cross the bed and floor planes.
3. The fully exposed eye, frontal muzzle and raised paws communicate alertness;
   the intended cozy world needs an unmistakably relaxed rest gesture.

**A. Meadows key-art belonging: no.** The Stronghold environment is outside this
pose review, but the creature's contorted alert silhouette does not carry the
key art's warm companion mood.

**B. Same kind of game as the Palworld references: no.** Terrapup's design is
colorful enough to belong in that category, but this animation presentation is
not production-character quality. The fix is pose structure and grounding with
the installed rig; these frames do not establish a need for new creature art.
