# Kontroller

Testet med Godot 4.7.2 på denne maskinen, AMD Radeon (TM) Graphics.

- Import og lasting av hovedscene: fullført.
- Automatisk kjørefysikktest: PASS. Stabil fjæring, akselerasjon,
  styring/sladd, reset og revers kontrollert.
- Fjæringshøyde i ro: 0,545 m. Hastighet etter tre sekunders gass: 51,8 km/t.
- Renderprøve: 47,75 FPS i gjennomsnitt over 120 renderbilder etter oppvarming,
  1280 x 720 vindu, 75 % 3D-oppløsning, Forward+, FSR, 2x MSAA.
  Fast kamera ved spawn; dette er ikke en garanti for alle kjøresituasjoner.
- 161 tegnekall og ca. 150 MiB grafikkminne i samme prøve.
- Windows release-eksport med innebygget spillpakke er produsert.

Ingen banegenerering ved oppstart. Alle baneobjekter har lagrede posisjoner.
Samlede mesh-filer reduserer tegnekall. Redigerbare lager/container-originaler
ligger i scenes/authoring, Blender-bilkilden i assets/source.

Grafikken bruker PBR-asfalt, HDR-himmel, metallakk, glass, skygger og tåke.
Geometrien er egenmodellert og stilisert; dette er ikke fotorealistisk AAA-grafikk.
