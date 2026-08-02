# D54. Four lighting defects that were all one shape: a number nobody read

Kind: implementation

A visual review of captured frames reported four blocking defects: nothing cast
a shadow, the sky was a flat single colour identical at morning and dusk,
distance got darker instead of hazier, and night was unnavigable. All four had
already been "solved" in comments. None of the solutions were wired up.

**The sky dome was 100m across and depth-tested like any other mesh.**
`infiniteDistance` pins a mesh to the camera; it does not push it to the far
plane. A 50m radius dome sat closer than every piece of terrain further away
than 50 metres and won the depth test against all of it, so the world ended
just past the player and the "far hill" the reviewer measured was 40m away.
That is why fog appeared to do nothing: there was no distance left to fog.
`sky.diameter` is now 1400, which clears the 384m terrain draw distance and
stays inside `camera.maxZ` of 900. This was also being blamed for a large dark
wedge in the survey frames; it is not that. Hiding the dome leaves the wedge,
and picking through it lands on `rig_11_Birb_Blob_primitive0`, a pal rig.

**The shadow frustum was never pinned.** `render.json` described a 70m box
around the player in detail, and `DirectionalLight.shadowFrustumSize` was never
assigned, so Babylon stayed on `autoUpdateExtends` and fitted the box to every
caster in the view distance: roughly 650m across a 1024 map, 0.63m per texel.
Worse, `bias` is a FRACTION of `shadowMaxZ - shadowMinZ`, and at 1..400 the
0.008 bias was 3.2 metres of depth offset, taller than anything the player
stands next to. Every contact shadow was pushed off its own caster. Pinned to
80m, bracketed to 30..300, bias 0.0002.

**The lighting was driven past the shader's clamp.** StandardMaterial clamps
the summed light to 1 before it touches the albedo. The palettes summed to 2.2
on open ground, so lit pixels and shadowed pixels both saturated to exactly 1
and the terrain rendered as flat albedo: no shading, no shadows, no shape. This
is the reason the first two fixes appeared to do nothing when they landed. Every
palette now sums to under 1 on flat ground, which is what makes a shadow a
visible thing rather than arithmetic that gets thrown away.

**The gradient was painted where nobody looks.** The dome ramp went zenith to
horizon linearly, and a third person camera at head height pitched down sees
about the first 25 degrees above the horizon. The whole interesting range was
overhead. `sky.horizonFalloff` is an exponent on sin(elevation) that pulls the
gradient into the band the camera can see.

Two consequences worth naming. `lighting.json` now carries six palettes and the
survey's two village hours land exactly on `day` and on `dusk`, so those frames
are as far apart as the cycle goes. And night's `ambientIntensity` is now
HIGHER than day's: night carries its floor with a saturated blue hemispheric
and a weak moon rather than with a bright one. The test that asserted the
opposite compared the wrong thing and now compares the light that actually
lands on the ground.
