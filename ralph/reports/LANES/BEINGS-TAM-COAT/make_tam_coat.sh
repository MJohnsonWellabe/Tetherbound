#!/bin/sh
# BEINGS-TAM-COAT (F38#16): Tam's tournament coat in slate blue (hue 212), made
# with the LANE-KIT F41#8 coat recolour, unchanged (olive coat cloth only; skin,
# hair, eyes and leather keep their pixels). Run from the repo root.
python3 ralph/reports/LANES/ITEM-F41-8/recolor_coat.py \
  assets/characters/villager_female/villager_female_lod0_texture_0_tam_coat.png 212 1.0 1.0 \
  assets/characters/villager_female/villager_female_lod0_texture_0.png
python3 ralph/reports/LANES/ITEM-F41-8/recolor_coat.py \
  assets/ui/portraits/npc_identity_meadows_tam_coat.png 212 1.0 1.0 \
  assets/ui/portraits/tam.png
