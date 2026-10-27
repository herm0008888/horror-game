# Creature test area

Main scene: `scenes/horror/test_area.tscn`. The earlier house is retained in `scenes/horror/main.tscn`.

WASD/arrows move at 2.25m/s, mouse looks, Ctrl crouches, E picks up the flashlight, F toggles it after pickup, R restarts, and Escape releases the mouse. There is no sprint or jump. Number keys reload distinct situations: 1 direct chase, 2 corner encounter, 3 obstacle chase, 4 dark flashlight pickup, 5 close encounter. Spawns are editable markers in separate scene files.

The creature has a 2.55m capsule and a 1.28 visual scale. Its head tracks the player's camera after detection. The visible green line draws its remaining collision-checked A* route. The planner connects current and destination positions with route markers and obstacle corners, and removes obsolete detours as soon as a direct route opens. Nearby cover peeks cannot take priority over a visible chase.

Quick corner peeks last 0.38s. Lean-in takes about 0.07s. Different valid corners can trigger in succession; each individual marker has a six-second reuse lockout. Peeking requires current nearby cover, an occluded body, a clear view from the leaned position and no retreat away from the target. A short forward burst follows the peek. The gait uses faster joint responses and shorter deliberate stalls.

The face uses an original smooth painted atlas, smaller eye protrusion, heavy eyelids, dark sockets and small dried blood smears. The body skin has a smooth base tone and blood on hands instead of periodic spots. Face geometry, the weighted neck and the Scream morph are stored in `assets/source/visitation_sculpt.blend` and exported to `assets/horror/visitation.glb`. `tests/prepare_horror_assets.gd` packs the runtime figure with its game materials.

The silent capture sequence places the camera on the head's forward axis, tracks the animated face center, opens the Scream morph and shakes the head and camera. It fades to black at 1.12s and restarts at 2.8s. It does not play a scream or catch sound.

Validation: `quick_corner_peek_test.gd` checks distinct-corner peeks, fast full lean, rapid pursuit resumption and repeated-corner suppression. `pursuit_path_test.gd` checks a short route around cover and actual capture. `test_situations_test.gd` checks all number keys and scene setup. `jumpscare_test.gd` checks frontal camera alignment, mouth morph, silence and death fade.
