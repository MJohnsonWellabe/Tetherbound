# Independent source review

Reviewer: /root/cloudreach_buttress_review, read-only.

Initial review found two blockers: proxy exit-face depth testing discarded cloud
in front of terrain, and nonzero density at the proxy boundary exposed hard edges.
Both were corrected: scene-depth reconstruction truncates the ray interval, and
an interior edge fade reaches zero at local extent 0.98. Follow-up review found
no remaining concrete blocker in those corrections; perspective depth ratio also
works with nonuniform proxy scale. Native plane/pillar diagnostic inspected.

Limits: terrain clearance uses five probes, not every point of the footprint.
Performance is pixel-bound and unproven on the Ally. Source review is not art
acceptance. Independent visual verdict remains A NO / B NO.

Final tint/config follow-up: no new concrete integration blocker. The optional
limestone_buttress_tint reaches the source_color stone_tint uniform through
normal _visual_rock_mass construction and multiplies imported albedo before
haze blending. White fallback preserves prior behavior; other rock paths are
unchanged. Cloud palette values likewise use the production material builder.
