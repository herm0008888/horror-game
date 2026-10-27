# Character material and eye revision

The source is `assets/source/visitation_sculpt.blend`, exported through `assets/horror/visitation.glb` and packed by `tests/prepare_horror_assets.gd`.

This revision removes the drooping painted eyelids and replaces the eye surfaces with complete, separately skinned eyeballs. EyeLeft and EyeRight are parented to Head. The EyeGaze node under Visitation aims each eye at the player camera after detection and at the active camera during capture. The pupils converge on the actual camera instead of remaining parallel or following a painted face. Tongue is an additional bone, bringing the rig to twelve bones.

The new tongue is a rounded, flattened skinned mesh with a closed-mouth folded state and a full-jaw Scream state. Teeth are individual tapered, crooked meshes with stained root-to-tip materials. The existing connected mouth cavity, retracted neck and editable capture camera path remain intact.

Face materials have separate diffuse, fine normal-detail and roughness maps. Pores are fine surface relief, without the former spotted albedo pattern. Eyes have small pupils, fine vein paint and a wet corneal material. Blood is painted onto the face, chin, clothing and hands; the rejected hanging blood-strand geometry is not included. Skin is mostly matte, with wetness confined to blood, eyes and tongue. The photograph is a visual reference only and is not projected onto the model.

Runtime materials are editable `assets/horror/materials/visceral_*.tres` resources using `visceral_pbr.gdshader`. Close encounter 5 uses darker lighting to emphasize highlights. The debug arena and visible navigation line remain available for testing.

Validation: `visceral_eyes_test.gd` checks both eye axes against left, right and lowered camera positions, and verifies a tongue bone. The pursuit, quick corner, all-situations and silent capture/swallow tests are rerun. The clean studio render is `../visceral-character-portrait.png`.
