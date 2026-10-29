# bil — Dockyard Drift

Åpne project.godot med Godot 4.7 og trykk F6 i scenes/main.tscn eller F5.

W / pil opp: gass. S / pil ned: brems og revers. A/D eller piler: styring.
Mellomrom: håndbrekk. R: sett bilen tilbake. Escape: avslutt.
Gi gass, sving inn og trykk håndbrekket kort for å sette i gang en sladd.
Kontrastyr og bruk gassen for å holde sladden.

Alle baneobjekter er lagret med transform i scenes/world/dockyard.tscn.
Props, bil og speedometer har egne scener. Ingen bane genereres ved oppstart.
Bilens fjærer, dempere, motorkraft og grep justeres i Inspector på Car.
Hjul og raycasts er egne noder under Suspension; Spawn er en flyttbar Marker3D.

assets/source/drift_coupe.blend er original Blender-kilde med navngitte deler.
Spillet bruker små GLB-filer, så Blender trenger ikke starte ved Godot-import.
Alle modeller, lyd og materialer er egenprodusert for dette prosjektet; ingen
nedlastede assets, eksterne biblioteker eller nettverk trengs ved kjøring.

Standard er Compatibility for rask oppstart og bred maskinvarestøtte.
For sterkere lys og SSAO: velg Forward+ i Godot, og start editoren på nytt.
Det er ingen menyer, poeng eller instruksjonstekst i spillbildet.
Dette er en spillbar enkeltbane med stilisert realistisk lys/materialer;
fotorealisme og ytelsestall er ikke garantert på uprøvd maskinvare.

Windows-versjon: ../Windows/Drift.exe, startes uten Godot-editoren.

Detaljerte originalscener for lager/container ligger i scenes/authoring/.
Spillet bruker sammenslatte mesh-filer fra assets/optimized/.
Etter endring av originalscene eller GLB, bygg cache paa nytt med:
Godot --headless --path . --script tests/bake_meshes.gd
