# Sight and storage hinge correction

House AI now requires forward-facing vision at every distance. The CellSightBarrier Area3D screens the full barred cell frontage on dedicated sight layer 8; it does not block movement or add visible geometry. Head/eye tracking requires current line of sight and a travel direction that does not lead away from the player. The eyes return to their neutral pose when tracking ends.

36 swinging doors/lids now have explicit saved hinge origins. Cabinet leaves pivot on the outer side edge and open outward. Oven door pivots on its lower edge and folds down. Crate/toolbox lids pivot on a rear/side edge and lift upward. Drawers retain translation only. Child meshes, collision shapes and ItemSlots were rebased together. Pivots and opening angles remain editable in scenes/horror/furniture/.

sight_and_hinges_test.gd: checks the grille screen between bars, blocked sight, rear vision, tracking while walking away/loss of sight, outward/upward opening, fixed hinges and return to the closed pose. 36 hinges, zero failures.
