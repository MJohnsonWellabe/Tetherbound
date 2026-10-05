Bounded own travel-view observation

Original Medium images0002 and0006 visually show bright interior plaster at23:00 in both clear and rain; rain is warmer/brighter. Same upper plaster ROI x150:650/y90:250 yields weighted sRGB luma138.183 clear versus159.525 rain (+15.44%). High equivalent137.587 versus158.341 (+15.08%). First matched travel block only; sky mostly occluded and no farmhouse doorway/light-off evidence. No physical luminance or isolated causal claim.

Source candidate: scripts/world/world_look.gd::_layer_weather still replaces night ambient_colour(#3d50a3 from art.json) with rain daylight ambient_colour(#7e8fa0), despite0.85 energy multiplier. Prior narrow fix affects only three sky color overrides, so ambient/facade verification remained open. Local farmhouse lights/tonemapping/renderer effects are not isolated. No further source patch in this observation.
