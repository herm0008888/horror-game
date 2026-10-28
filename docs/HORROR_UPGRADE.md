# Horror upgrade — 28 October 2026

Main scene: `scenes/horror/house_layout.tscn`. Original wood wall materials preserved.

## Play
E: collect hammer through the cell bars, open storage, pick up loose objects.
Left mouse: swing equipped hammer at cracked wall repairs (cell: two strikes).
Ctrl: crouch through the opening. Q: drop held object/tool; G also drops loose objects.
The west upstairs service crawl connects master bedroom and store. Additional damaged repair connects the east and south bedrooms behind the wardrobe. The ground-floor ladder is enclosed in a broom closet, with a usable doorway. Two deep wardrobes conceal the player with their doors closed.

## Creature
Restrained dragging walk, faster asymmetrical pursuit, brief head/shoulder spasms; reduced arm flailing. New UV-aligned ashen face texture, shorter stained teeth, narrower eye sockets and darker eyes. Immediate jumpscare sound/camera, limited mouth opening and short face lunge; camera no longer moves through the mouth. No perception-through-walls changes.

## House
All upstairs rooms furnished, including three bedrooms, bathroom, store and landing; secret service crawl and breakable repairs. Additional Poly Haven CC0 models, aged wood, stains, dirty glass, scattered belongings and working drawers/doors. Loose objects and hammer use rigid bodies; creature/player can push them.
Source manifest: `assets/house_library/UPPER_FLOOR_SOURCES.json`. License: https://polyhaven.com/license . Unused downloaded pillows retained as optional source assets.

## Rendering
Static decorative meshes grouped by material; structural batches kept spatially small. Imported mesh LODs, distance culling of small details, light/shadow distance limits, hole-aware structural occluders and conservative floor/stair visibility. Physics and enemy AI remain active on hidden floors. Standing capsule query reused rather than allocated every frame.
Fixed 1280x720 benchmark, six views in each lighting mode, same machine: average per-view median frame time 10.659 ms before / 8.678 ms after (18.6% lower); draw calls 388.42 / 296.25 (23.7% fewer). This includes the added upstairs content. Scene loading was 21.7 s / 26.1 s; extra assets increase initial loading. Results vary by room and do not imply a universal FPS increase.

## Validation
Automated gameplay: hammer pickup through bars, damage/opening, gravity/drop, cupboard concealment, standing/crouching crawl traversal, return routes, ladder doorway clearance, ground-floor walking routes, interactive storage hinges, jumpscare at 30/60/120 FPS and enemy stair traversal. Visual room and creature captures retained in the task outputs. Godot emits pre-existing resource cleanup warnings on test shutdown.
