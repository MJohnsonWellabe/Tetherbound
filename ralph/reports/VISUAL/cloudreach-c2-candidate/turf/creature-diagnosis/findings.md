# Owner creature defect diagnosis

Seven native Windows NVIDIA Compatibility 1920x1080 diagnostic frames individually inspected. Neutral diagnostic stage, not production-camera acceptance evidence.

Cloudfang ordinary is white/pale blue; set_shiny(true) reproduces the solid hot-pink creature. No authored cloudfang shiny texture is installed. creature_body.gd falls back to SHINY_PLACEHOLDER_TINT Color(2.6,0.12,2.6), multiplying the source material. This is a shipped placeholder presentation path, not a missing GPU texture. Needs an authored region repaint retaining face and fur detail; not fixed by this checkpoint.

Galecrest rest pose has an intact upright neck. Its sampled idle changes head/neck and upper-body posture substantially. rig_bird.py authors head turn 24deg, head nod 11deg, neck nod 8deg plus spine movement. These samples support investigating the animated pose/weights before regenerating the mesh; they do not establish the exact broken-neck pose's root cause. Next compare full-cycle front/profile motion and inspect axis/weights. Owner raised Meshy replacement; retain existing identity and scale if new art is warranted. No Meshy run was submitted for this diagnosis.

First diagnostic attempt had inactive animation evaluation and weak ambient light; discarded for pose comparison. This retained version explicitly evaluates animation manually and uses lit ambient. No acceptance PASS is claimed.
