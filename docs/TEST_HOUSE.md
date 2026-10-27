# Det forlatte huset — stor testscene

Start med F5. Scene: scenes/horror/rundown_house_test.tscn.

14 innredede rom over tre nivåer, med 117 plasserte møbler/props og 44 ulike nedlastede modeller. Alle miljømodeller og overflateteksturer er nye Poly Haven-assets fra house_library; ingen gamle husmøbler eller husteksturer er brukt.

Hovedetasje: stue, spisestue, kjøkken, sykestue, vaskerom og verksted.
Loftsetasje: soverom, gjesterom, arbeidsværelse og loftsbod.
Kjeller: kjellerrom, lager, fyrrom og redskapsrom.

WASD: gå. Mus: se. E: åpne/lukke dør eller gulvluke. F: lommelykt.
Ctrl: snik. M: romoversikt. L: arbeidslys på/av. R: tilbake til inngangen.
Esc: slipp/fang mus.

Trappen ligger bakerst i midtgangen. Fra inngangen går første trapp opp; for å gå ned til kjelleren, bruk reposet bakerst eller åpne gulvluka ved inngangen. Se ned og trykk E på luka. Fallet lander på kjellergulvet. R gir alltid en trygg vei tilbake til inngangen.

Dette er den ferdig innredede miljøtestscenen. Håndsekvensen, oppvåkningen og videre spillmål bygges som egne spillsekvenser senere.

Assets: Poly Haven, CC0. Se assets/house_library/SOURCES.json og CREDITS.txt.
Ny romgeometri, dører, trapp, luke, bevegelser og lyder er laget for scenen.
Styrings- og dørskript: scripts/horror/test_house*.gd.
Scenen har lagrede noder og kan redigeres direkte i Godot.
Gjenoppbygging: tools/house/build_test_house.gd (overskriver den genererte testscenen).
Validering: tests/test_house_test.gd kontrollerer alle 14 gulv/døråpninger, faktisk trappevandring begge veier, luke/fall og trygg omstart. FULL_HOUSE_TEST PASS.
