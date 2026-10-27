# m50: chapter-wide storm light grade (CPU, code-blind, 27 Oct): NO GAIN (+0.04), first miss

**Arms:** six stands, calm and break: Crown Overlook, Struck Sentinel, Glass Field, Rodline Post, the deep forest and the Fallen Giant grove.
- **OFF:** the lane.
- **ON:** `stormwood_look.json storm_grade`:
  - a camera-relative directional rim from beyond the subject toward the camera, 22 degrees down, diffuse only (a first try with specular 0.5 put a white hot spot on the wet forest ground and was re-captured before judging);
  - rim energy per phase 0.55 / 0.8 / 1.1 / 0.7, plus 2x the surge flash;
  - a per-phase grade (brightness / contrast / saturation): calm 1.02/1.08/0.98, building 0.97/1.14/0.9, break 0.95/1.2/0.85, fading 1.0/1.1/0.94.

**Result:** mapped **6.15 -> 6.19 (+0.04)**. Judges scored 5.6/5.6, 5.7/5.8, 5.5/5.5 and all call the arms near-identical. Linear fit, no warnings.
- **No storm light in the scene:** PARTIAL on both arms.
- **No rim:** PRESENT on both arms 3/3.

**Why:** a diffuse light travelling straight toward the camera only lights the faces turned away from the camera, so no visible edge lights up. The break grade (brightness 0.95, contrast 1.2) darkened break further, and the judges ask for the opposite: "break phases brighten edges at the strike instead of going uniformly darker".

**Decision:** first miss. Second try (m50b):
- a three-quarter back light from the side (camera-relative, about 60 degrees off the view axis) so the lit side edges of trunks and figures face the camera;
- stronger rim energy;
- break graded brighter, not darker;
- the existing decorative-bolt ground exposure (`sky_lightning.ground_light_exposure`, 0 today) turned on, so the strike lights the scene.
