# Dense woodland update

Edit scenes/horror/abandoned_exterior.tscn for the outdoor set.
DenseFirForest contains 837 individually positioned mature firs, sharing one
6,124-triangle trunk/branch mesh plus three baked alpha-cutout crown textures.
Trees use automatic mesh LOD and distance culling. YoungTreesAndDeadfall adds
58 young trees; MossyStonesAndForestDebris contains 70 scanned mossy rocks.

WornEarthAndGravelPath is a continuous mesh following the terrain surface.
UnevenForestGround blends two PBR texture sets with tangent-space normals.
WeatherboardFacade matches existing solid wall segments, leaving openings intact.
WindowDepthGuttersAndFoundation contains window surrounds, sills, shutters,
boards, foundation, gutters and attic vent. Roof uses scanned slate textures.
BrokenPicketFence replaces the simple rail fence. Entrance has an actual caged lamp.

All objects are saved editor nodes. No runtime forest generation.
ForestBatcher groups static render meshes by 12 m cells while playing; source tree
nodes remain individually editable. This reduces draw calls without changing placements.
Tree trunks and ground have collisions. Coarse outdoor navigation avoids trunks
and connects to the entrance. Dynamic indoor navigation is unchanged.

ExteriorStory is a separate scene with editable captions, a scarf clue and markers.
The authored StoryStart marker sets the outdoor start; set ExteriorStory.start_outside
false for tests that need to keep their own spawn. The original T cellar reset remains.
See WOODLAND_STORY.md for story, current implementation and later audio/cinematic ideas.

Validation: 11 woodland/story checks passed, including route to porch and door interaction.
Native D3D12 visual inspection performed. No universal FPS guarantee is implied;
dense woodland adds rendering work relative to the previous sparse test area.
CC0 credits: assets/exterior/CREDITS.txt (Powered by Poly Haven).
Backup: Codex workspace outputs/backups/before-dense-woodland.
