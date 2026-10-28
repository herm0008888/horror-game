# Decor and rendering optimization

37 new editable decorative objects: 30 stones (six scanned variants, 13-27 cm horizontal dimensions), five oil tins and two small oil cans. All are saved in stone_workshop_decor.tscn; each stone variant has its own scene in scenes/horror/decor/. Positions, dimensions and sources are recorded in tools/house/stone_decor_placements.json. Objects are decorative; routes remain unobstructed.

## Sources
Powered by Poly Haven. CC0 assets, https://polyhaven.com/license
- https://polyhaven.com/a/rock_moss_set_01
- https://polyhaven.com/a/oil_tin
- https://polyhaven.com/a/small_oil_can_01
Original 1K glTF downloads and MD5 checksums: assets/house_library/DECOR_STONES_SOURCES.json. About 5 MB of additional source assets. Existing textures and model detail are preserved.

## Optimization
HouseOcclusion is an editable scene with three OccluderInstance3D nodes, assembled from 211 solid structural wall/slab boxes. Each is inset 6 cm, including warped plaster walls. Door gaps, stairwells and hatch/ladder/plank openings are excluded. Rebuild with tools/house/build_occlusion.gd after changing the structural walls. Rendering occlusion culling is enabled in project settings.

Heavy embedded basement meshes use 28 shared compressed binary resources. Geometry and materials are unchanged. Basement scene/mesh storage fell from 13,644,810 to 10,771,104 bytes (21.1%). The export tool compact_basement_meshes.gd and apply_compact_meshes.py are for authoring, not runtime; they preserve the scene text and material overrides.

## Measurements on this PC
1280x720, vsync off, six fixed views in each lighting mode, 30 warmup and 60 measured frames per view; full-quality geometry/textures throughout.
- Horror lighting: 55.2% fewer visible draw calls; mean of per-view median frame times 12.93 ms to 11.97 ms.
- Work lighting: 56.7% fewer visible draw calls; mean of per-view median frame times 11.45 ms to 10.94 ms.
- All 12 before/after culling image pairs were pixel-identical. All 12 before/after mesh compaction pairs were pixel-identical.
- Actual performance varies with resolution, camera view, other applications and hardware; these measurements are not an always-smooth guarantee.

## Validation
stone_decor_test.gd verifies contact and dimensions for all 37 objects. test_ground_floor.gd checks 14 routes with actual active static collisions; scripts/player movement are paused rather than disabling the physics bodies. The east kitchen aisle is tested at x=11.3 to clear the existing cupboard. No furniture or gameplay collisions were moved.
Benchmark and visual comparison JSON files accompany this document. Main fullscreen, brighter ambient light, flashlight and L lighting controls are retained.
