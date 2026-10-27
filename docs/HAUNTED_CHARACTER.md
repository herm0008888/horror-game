# The Hollow Visitor

Current material, anatomy and eye-gaze notes are in `VISCERAL_CHARACTER.md`. The rig now has twelve bones, with independent EyeLeft and EyeRight gaze and a skinned tongue. The head and mouth use original textured geometry rather than a projected photograph. Hanging blood-strand geometry is not included.

Editable source: `assets/source/visitation_sculpt.blend`. Runtime: `assets/horror/visitation.glb`, packed into `scenes/horror/figure_visual.tscn` by `tests/prepare_horror_assets.gd`. The Scream shape opens the actual jaw, cavity, teeth and tongue and retracts the neck. The source retains an editable walk action; the runtime gait and quick corner behaviors live in separate scripts.

The current playable scene is `scenes/horror/test_area.tscn`. `JUMPSCARE_EDITOR.md` documents the saved camera, mouth-entry path and reach-pose nodes. `CREATURE_TEST_AREA.md` documents controls and number-key situations.
