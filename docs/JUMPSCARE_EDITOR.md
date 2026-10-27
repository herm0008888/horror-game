# Editable jumpscare setup

Open `scenes/horror/visitation.tscn` in Godot. Expand `Figure/JumpscareSetup`. Its children are editable in the figure scene. The reusable setup is saved separately in `scenes/horror/jumpscare_setup.tscn`.

- `CameraShake/JumpscareCamera`: the actual capture Camera3D. Move or rotate it in the editor and use the Camera Preview. Its local transform and FOV are respected at runtime.
- `CameraShake`: saved camera position and the small shake pivot, placed at camera height rather than at the floor.
- `HeadPose`: saved neutral head rotation for capture. It defaults to looking forward and slightly down; yaw and roll are zero.
- `FaceTarget`: composition reference marker for the center of the opened face.
- `CameraShake/JumpscareCamera/FaceLight`: editable light for the capture shot.

`Player/Jumpscare/DeathUI/Black` is the saved death fade UI. Capture switches to the figure's camera; it does not generate a camera or a CanvasLayer or reposition the player camera. The controller resets the walking head and body pose, uses HeadPose, and shakes the parent pivot without changing JumpscareCamera's authored transform.

The upper neck retracts behind the open jaw in the actual Blender Scream shape key. The old shader-only neck displacement is removed, so the fix is present in solid view as well as in the game.

Validation: the capture test begins with a side-tracked head and body roll, then verifies use of the figure's camera, unchanged local camera transform, frontal composition, zero body roll, the Scream morph, silence and death fade. A solid-material Blender render verifies neck clearance independently of the mouth shader.


## Physical mouth and swallow sequence

The shader-painted black mouth ellipse has been removed. The mesh has a real mouth slit connected to a deep closed cavity, plus separate tooth surfaces. The Scream key moves the whole lower jaw, upper lip, cavity and teeth, while retracting the neck/collar behind the mouth. The Blender source can be inspected with Scream=1 in solid view.

`Figure/JumpscareSetup/MouthEntry` and `SwallowEnd` are authored camera-pivot poses. The camera stays in front while the jaw opens, then the pivot passes through these poses into the mouth. `ReachPoses` contains editable marker rotations and bone-name metadata for the reaching arms and forearms. The child Camera3D's local editor transform remains unchanged. The FaceLight dims during entry and the death overlay fades after 1.12s, as the camera reaches the interior. The jaw bites down and closes fully behind the blackout. The sequence remains silent.

The capture test checks actual cavity material/geometry, the jaw morph, editor-camera usage, frontal composition, movement toward SwallowEnd, silence and the death blackout.
