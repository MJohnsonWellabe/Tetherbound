Shipping draw-distance floor candidate, unmeasured contribution

All four independently preserved actual-release main33431f9abab32c28898d52daecbd24f48012c490 receipts record camera_far_m2000 for Meadows Low+Medium and6500 for Tidewake Low+Medium. Authored graphics Near/Normal/Far distances are320/520/900m with meshLOD thresholds4/2/1. graphics_prefs.gd::apply_camera takes max(presetfar,vista_far_floor_m), so the chapter floors override the camera clipping portion of these draw-distance settings. Low stillchangesLOD/shadows/supportedfeatures; it is not identical toMedium.

Water world explicitly sets the6500m floor from water_visual.json to preserve sea horizon and Veilfall near4km. Cloudreach config has3500m vista floor; that was not part of the four measuredshippingcases and no performanceclaim follows. Meadows horizon uses2000m floor as confirmed in receipts.

This explains why switching Low does not shorten the actualcamera range in measuredchapters. It does not measure how many distant objects/fragments/colliders/AI callbacks remain active or prove a CPU/GPU bottleneck. Longcamera range can coexist with per-objectLOD/culling/occlusion; terrain/sky/horizon requirements remain. The blocked PERF detail-cull source proposal must preserve pickup glow/required landmarks; do not solve this by clipping mandated vistas or broadly merging rejected source.

Source/runtime observation sent for owning PERF lane review; no game patch or newtool/test. Actual-release TidewakeMedium9.615FPS/Low8.385FPS andMeadows12.266/11.129 remain20FPSfloorFAIL. Prior comparable release baseline missing; regression onset and dominant causeOPEN.
