# Husets overflater

Fire delte materialer fra assets/house_materials er lagret direkte på mesh-nodene i
scenes/horror/house_layout.tscn. De vises også i editoren.

- wall_wood: house_library/wood_planks_dirt — vegger og rekkverk, 2 meter per repetisjon.
- floor_wood: house_library/old_wood_floor — etasjegulv, trinn og repos, 3 meter per repetisjon.
- basement_wall: house_library/cracked_concrete_wall — kjeller- og tunnelvegger, 2 meter per repetisjon.
- basement_floor: house_library/concrete_floor_damaged_01 — kjeller- og tunnelgulv, 3 meter per repetisjon.

Alle bruker eksisterende diffuse-, normal- og ruhetskart med matt overflate.
World triplanar-mapping holder målestokk og teksturposisjon sammenhengende mellom
veggsegmenter, gulvbiter og åpninger. Testrutene er skjult; kollisjoner og passasjer er bevart.

Etter eventuell gjenoppbygging med build_layout.gd kan materialene påføres igjen med
Godot --headless --path . --script tools/house/apply_surface_materials.gd.
Skjermbilder kan kontrolleres med tests/house_surface_visual_check.gd.
