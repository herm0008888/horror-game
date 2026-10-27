# Lys i huset

Huset starter med skrekklys: dempet kaldt omgivelseslys, små varme lyspunkter,
reelle skygger og kaldt lys inn fra vinduene. To lys varierer svakt i styrke.

L bytter til normalt, lyst arbeidslys. L igjen går tilbake til skrekklys.

Åpne scenes/horror/house_lighting.tscn for å flytte og stille inn de navngitte
SpotLight3D-nodene. Dette er en egen scene som er satt inn som Lighting i huset.
Environment-noden i hovedscenen bruker delte ressurser fra
assets/house_materials/horror_lighting.tres og normal_lighting.tres.

Controller: scripts/horror/house_lighting.gd. Inspector-verdien flicker_amount
styrer den lette variasjonen i CellLamp og UpperLandingLamp; sett 0 for fast lys.

Normalmodusen aktiverer husets opprinnelige OmniLight3D-noder og gjenoppretter
omgivelseslys på 0.75. Validering: tests/house_lighting_test.gd sender L-trykk,
sjekker begge moduser og at tastaturrepetisjon ikke bytter frem og tilbake.
