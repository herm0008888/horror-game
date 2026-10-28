# Furnished ground floor

The main house now instances seven editable dressing scenes: living room, kitchen/dining room, study, utility room, front store, hall/landings and architectural details. The existing cellar and upstairs layout remain intact.

114 placed model groups (including sets of books, bottles and candleholders), plus skirting, door liners, window frames, sills, worn rugs and small plaster debris. Models are measured in metres before placement. Tabletop and shelf objects are positioned using ray intersections with the actual furniture meshes. Structural cupboard collisions retain the original crawl-space clearance.

## Walk-through

Run `scenes/horror/house_ground_floor_preview.tscn` to start in the furnished living room with inspection lighting. WASD: move; Ctrl: crouch; E: interact; L: toggle horror/inspection lighting; T: replay the trap intro. The main game still starts with the cellar intro.

## Sources

15 additional Poly Haven models, CC0 1.0: sofa_02, desk_lamp_arm_01, pot_enamel_01, wooden_bowl_01, wooden_spoon, carved_wooden_plate, wine_bottles_01, brass_candleholders, multi_cleaner_bottle, plastic_broom, ornate_mirror_01, standing_picture_frame_01, dining_table, book_encyclopedia_set_01, wooden_bucket_01.

Source URLs and verified downloads are recorded in `assets/house_library/GROUND_FLOOR_SOURCES.json`. Existing asset sources remain in `SOURCES.json`. Original 1K glTF downloads and dependencies were checked against the provider's MD5 hashes. License: https://polyhaven.com/license

## Validation

- `tests/test_ground_floor.gd`: player-sized capsule clearance along fourteen ground-floor routes.
- `tests/test_basement.gd`: intro, cellar escape, both main staircase levels, cupboard tunnel both ways, bedroom passage, foundation tunnel and concealed ladder both ways.
- `tests/test_bridge.gd`: trap walls, fall without plank, pickup, placement, crossing both ways and intro reset.
- `tests/ground_visual.gd`: eight room views and one horror-lighting view for placement review.

The authoring tool is `tools/house/furnish_ground_floor.gd`. It replaces only its own dressing node and updates the ground-floor finishes. Do not rebuild the original blockout to update decoration.
