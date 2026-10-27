# Mørkt hus og lommelykt

Skrekkmodus har nå svært lite omgivelseslys (0.025), svakere og smalere lampelys
og mørke områder mellom lampene. L gjenoppretter det opprinnelige arbeidslyset.

Lommelykten ligger ved landingsstedet i kjelleren: se mot den og trykk E.
F slår den av og på etter opptak. Den lyser automatisk ved opptak.

Player/Camera/FlashlightRig er en instans av house_flashlight.tscn med egen
modell, Beam og Spill. Posisjon, rekkevidde, lysfarge og vinkel kan redigeres i
scenen. Beam kaster skygger; Spill er et svakt lys nær hånden.
FlashlightPickup er en egen node i huset og bruker det eksisterende opptaksobjektet.

Styring: house_flashlight.gd. layout_player.gd utfører en kort interaksjons-raycast
fra kameraet og bruker den eksisterende acquire_flashlight-funksjonen ved opptak.

Test: dark_house_flashlight_test.gd kontrollerer faktisk siktlinje og E-opptak,
F av/på, mørkt startlys og L tilbake til normalt arbeidslys.
