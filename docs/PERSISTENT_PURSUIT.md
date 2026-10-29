# Persistent pursuit

House enemy uses navigation paths plus collision-tested local recovery for moved furniture and doors. Recovery measures horizontal progress so floor contact jitter cannot hide a blockage. It preserves the chosen passing side briefly instead of oscillating against furniture.

Sight samples the player head and torso from stable body heights; solid walls and grille sight areas still block it. On sight loss, one short prediction uses only the last observed velocity, followed by up to 25 seconds of investigation and 16 seconds of nearby waypoint searches. Hidden player movement does not update the destination. Quiet footsteps cannot replace a stronger active clue. Breaking a wall carries 35 metres and sets a location clue across floors.

Chase animation uses an opening/snapping Scream blend shape cycle, forward arm reach and uneven body motion, preserving the straight elbow rest rig. No new geometry or camera effects.

Tests: house_pursuit_routes_test.gd, house_pursuit_behavior_test.gd, sight_and_hinges_test.gd.

Door opening by the enemy suppresses its own AI hearing event. Previously this replaced the chase goal with the door position and caused an early investigation/search, especially at staircase doors. Local sidestepping is limited to level floors to preserve ramp traversal.
