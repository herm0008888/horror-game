# Straight arm revision

The active Godot body was brought into Blender with its exact 20,803-vertex order. The elbows now follow continuous shoulder-to-wrist centerlines, with an even tapered contour instead of the old pinched, offset joint. Both upper-arm and forearm rest axes and skin bind transforms were fitted to the corrected shape. Idle/chase elbow rotations were reduced while the existing arm swing and body movement remain.

Editable Blender source: assets/source/visitor_straight_arms.blend. The scene Visitor_Arm_Correction contains the textured character and an editable arm skeleton. The original open Blender scene and original source files were preserved. The new source has packed textures.
Runtime body: assets/horror/visitor_straight_arms.res, with visitor_straight_arms_skin.tres. figure_visual.tscn uses the new body and fitted bone rest poses, so the main house and jumpscare use the same revision.

All 12 mesh surfaces, both facial blend shapes, texture coordinates, original materials and distance LOD indices are retained. Only body-surface arm positions/normals and four arm rest transforms/bind poses were updated. Face geometry and all other mesh surfaces compare exactly with visitor_complete.res.

Validation: straight left/right elbow axes; all 12 rest skin bindings equal identity; unchanged non-body vertices; original face blend-shape count and body LODs retained. Inspected in rest and animated chase poses.
