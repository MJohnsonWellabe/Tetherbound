# LAND-MT-STEEPGRASS (F38#30): PARKED on CPU after two misses, not sent

Ask: "smeared low-resolution grass texture" / "stretched grass on the steep face" on the Warrens near flanks (walk_02, walk_03).
Code: flag-off `bank.hill_shell.meadow_match.steep_fix`. It stays OFF; the code is on `tb/land-mt` only.

1. Triplanar broad tone (it was sampled top down) plus anisotropic fine grass: no visible change on walk_02 or walk_03.
2. Plus a sharp triplanar blend (pow 16 instead of 4), so one projection dominates on 45-degree flanks: no visible change either.

So the smear is not the projection. My next guess is the grass sheet itself: a soft, low-contrast texture at 0.27 tiles per metre, magnified on near flanks. The judges' "higher-frequency rock and moss material" ask points the same way. That would be a different texture or a detail layer, not a projection fix. Not started.
