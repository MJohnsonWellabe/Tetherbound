# Exposed bank material diagnosis

The CPU probe loads baked Terrain3D region height/control images at dunes-04
source `0930716acaf88f4827576b050e782c32fb46269e`. It does not launch a world,
import assets or render. Its standing height differs from the capture by
0.00000155 m. Pixel rays use the recorded camera basis and 70-degree field of
view with CPU bilinear intersection; these are not rendered depth samples.

Representative visible Sluice bank slopes are 34–74 degrees, all painted base
and overlay texture ID 2. Gentle foreground is ID 0 at 8–13 degrees. The former
mineral mask starts at 43.95 degrees and reaches full weight at 67.67 degrees;
it therefore misses or weakly treats much of the visible bank. The interpolated
Terrain3D normal is correctly world-space. A separate error remains at full
weight: remapping mineral luminance into a beige color still makes rock sandy.

The next disabled candidate supplements the steep mask with painted rock
between normal Y 0.90 and 0.70. The measured 39-degree bank receives about 68%
mineral before noise; 46-degree and steeper painted banks receive full mineral.
The mineral mask reduces dune replacement instead of recoloring rock, retaining
the installed coastal Rock030 treatment's albedo, normal, roughness and normal
depth at full coverage. Wet-height protection, Veilfall exclusion and terrain
geometry remain unchanged. Gentle ground retains the dune surface.

Independent source review found no actionable shader/mask issues. This is a
diagnosis and an unjudged candidate, not native visual acceptance. Fresh scene
materials must be used because the installer retains already-injected shaders.
Run `probe.gd.txt` as a local `.gd` SceneTree script using headless Godot; its
JSON sample results are retained beside this note.
