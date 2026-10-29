# Exterior and pursuit update

Open scenes/horror/abandoned_exterior.tscn to edit the outdoor area.
It is instanced in house_layout.tscn as AbandonedExterior.
All trees, paving, roof sections, fences, lights and cameras have saved editor transforms.
The front door is a separate FrontDoor instance in house_layout and opens with E.
The outdoor path leads forward from the door, then right.
CinematicMarkers contains Doorway, HouseEstablishing and ForestRight cameras, not active during gameplay.
This is a set for a future animation; no cutscene timeline has been added.

91 shared textured tree instances, simplified in Blender, 1K textures.
Uneven terrain uses a saved mesh and matching collision. Separate outdoor navigation joins the entrance.
Local mist cards supplement smoothly blended outdoor distance fog. L retains normal lighting.
CC0 nature credits are in assets/exterior/CREDITS.txt (Powered by Poly Haven).

Pursuit: repeated update requests no longer reset the navigation debounce indefinitely.
Furniture footprints are carved out so furniture tops are not walkable islands.
Step-up checks require a matching walkable route; perched enemies look for a clear lower landing and walk off.
No teleport recovery and no wall collision bypass.
Screen effects add restrained edge chromatic separation and desaturation during pursuit.

Validated: opening front door, outdoor connected route, repeated rebuild requests, escaping sofa.
Existing room and stair pursuit regression tests run separately.
Backups: outputs/backups/before-forest-recovery in the Codex workspace.
