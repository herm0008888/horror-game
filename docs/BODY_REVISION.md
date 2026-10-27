# Kropp og rigg

Kroppen er bygget om som en sammenhengende anatomisk mesh med sammenføyde
skuldre, overarmer, albuer, underarmer, håndflater og fingre. De gamle revnede
skulderflatene og den uproporsjonalt lange underarmen er erstattet.

Arm- og underarmsbeina følger den nye anatomien. Den smale overkroppen har en
formsydd, slitt kjole med modellerte folder og ujevn kant. Hud og kjole har egne
UV-teksturer med uregelmessige blodflekker og matte materialer. Hals og krage
flyttes bakover sammen med Scream-formen for å gi plass til den åpne kjeven.

- Blender-kilde: assets/source/visitation_sculpt.blend
- Spillmodell: assets/horror/visitation.glb
- Redigerbar Godot-scene: scenes/horror/figure_visual.tscn
- Materialer: assets/horror/materials/visceral_body.tres og visceral_cloth.tres
- Nye teksturer: assets/horror/anatomy_*.png

Ansikt, blikkstyring, de 12 riggbeina og den nye AI-en fra den andre PC-en er bevart.
Modellen har omtrent 50 000 vertices i Blender og bruker samme åtte materialflater.
Kontrollert med body_visual_check, erratic_motion_test, visceral_eyes_test og jumpscare_test.
