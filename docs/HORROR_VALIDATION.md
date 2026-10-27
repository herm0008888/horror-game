# The House — validering

Godot 4.7.2, Windows, integrert AMD Radeon (TM) Graphics.

- Hovedscene: scenes/horror/main.tscn.
- Funksjonstest: gulvkollisjon, førstepersonsbevegelse, dørhengsler,
  full trappepassasje, fiendens syn og navngitte animasjonspivoter.
- PSX-uttrykket kontrollert i et faktisk renderbilde fra spillet.
- Patruljeruten har 25 manuelt plasserte Marker3D-punkter.
- Utvidet patruljetest: PASS. Figuren nådde alle 25 ruteindekser,
  åpnet alle åtte dørene og gikk mellom begge etasjene.
- Huset, møbler, dører og lys har lagrede editor-posisjoner.
- Ingen inventory eller item-puslespill. Dette er en utforskings- og
  unnvikelsesversjon med automatisk omstart når spilleren blir tatt.
- Hus, figur, pikselteksturer og lyder er egenprodusert for prosjektet.
  Modellens Blender-kilde: assets/source/visitation_sculpt.blend.

PSX-stilen bruker 640x360, heltallsoppskalering, små teksturer,
nearest-filtrering, affine UV-er, vertex-snapping og filmstøy.

Teksturfiks: fjernet vertex-snapping, affine UV-er, skjermbasert dither og
animert bildest�y/forvrengning. Kamera-retur og tidsstabilitet: PASS,
0 endrede fargekanaler i renderkontrollen med frosset spilltilstand.

Ny figur modellert gjennom Blender MCP etter brukerens referanse.
Ett skinnet render-mesh, fem materialer og ni riggknokler. Huden er
voxel-sammenf�yd, med formede ansiktsdetaljer og malte UV-teksturer.
H�r, �yne og kl�r inng�r i samme render-mesh med egne materialer.
Riggens hvilerotasjoner bevares under gange og jakt. Spilltest: PASS.

Material- og lysoppdatering: kontrollerte renderbilder fra gang, stue,
kjoekken og soverom. Egne materialressurser med fysisk teksturstoerrelse,
verdensjusterte vegg/gulvflater og lokale moebelteksturer. Pusset underside
paa etasjeskillerne. Space/no-jump, doerer og trappegang: PASS.
