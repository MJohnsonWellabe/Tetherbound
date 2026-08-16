extends "res://scripts/world/gated_crossing.gd"

## SC14 — the South Bridge, spec §3's Gate 1.
##
## The whole mechanism lives in `gated_crossing.gd`, which this file was
## before `SE22` needed the same crossing built a second time over the river.
## What is left here is what is actually specific to this bridge: which
## `crossings[]` entry it is, which key opens it, and which flag remembers.
##
## Beating Oskar yields the South Bridge Key (`SC13`).


func _init() -> void:
	super("south_bridge", "south_bridge_key", "south_bridge_open")
