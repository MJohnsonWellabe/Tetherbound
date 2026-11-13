STATUS: land

# THINGS-POSEPRESET landing (pose stage applies the graphics preset)

Branch `tb/things-posepreset-land`, cut from main c73dcc80. Tooling only: `tools/_capture_creature_roster.gd`.

**Blocker (GPU lane, reproduced).** The roster stage builds its own environment, lights and camera and never called `scripts/ui/graphics_prefs.gd`, so High and Medium rendered identically. Every F36 "Medium" from this stage was a second High render, including the Medium evidence behind F36#72 Stormbrush, F36#69 Solmane, F36#58 Pebbik and F36#35 Breezetail.

**Fix.** After the stage environment, key light and camera exist, the stage calls `load_preferences`, `apply_environment(env)`, `apply_sun(key)`, `apply_viewport(root)`, `apply_camera(camera)` (the order world_look.gd uses) and prints `STAGE graphics preset applied: <name>`. `--no-graphics-preset` restores the old stage for reproducing earlier rounds.

**Reach.** The same base serves `capture_f36_poses.gd`, `capture_creature_clips.gd` and `capture_creature_turntable.gd`; all three now follow the preset.

**Consequence to plan for.** High frames change too: this is the first time the High preset (glow, SSAO, shadow profile) reaches the stage, so earlier High pose scores were taken on a preset-less render. Rows judged from here are on the real presets; a base and its arm must both be captured after this lands.

**Check (CPU, Compatibility, Low).** Mirejaw hit: the log shows `STAGE graphics preset applied: Low`; with `--no-graphics-preset` the line is absent. The two frames differ only slightly at Low (shadow profile; mean difference 0.03), as expected on this renderer, which has no glow or SSAO. No script errors. **Not verified here:** that High and Medium now differ; that needs the GPU.
