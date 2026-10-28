# Asset- og FPS-optimalisering

Oppdatert 28. oktober 2026 i `C:/Users/hersv/Documents/horror-game`.

- 187 teksturimporter begrenset til 512 px for småting og opptil 1024 px for store flater/møbler og ansikt. Originalbildene er beholdt. Alle importstørrelsene er kontrollert.
- 67 statiske rendermesher forenklet forsiktig: totalt 1 726 860 → 921 341 trekanter i de lagrede statiske meshene (46,6 % færre). De endrede meshfilene gikk fra 32 439 124 til 15 040 403 byte. Kollisjoner og navigasjon ble beholdt.
- Hår, kropp og kjole har fått avstands-LOD. Nærgeometri, beinvekter og ansikts-blendformer er kontrollert mot sikkerhetskopien innen serialiseringspresisjon. Ansikt, øyne, tenner og munn har full detalj uten nye LOD-er.
- Direct3D 12 med Godots Mobile-renderer er nå standard på Windows. Det unngår den tidligere OpenGL-oversettelsen på denne maskinen.
- 60 FPS-grense. 3D-bildet tilpasses GPU-belastning; UI har skjermens oppløsning. Ved 1920×1200 utgang var 3D-oppløsningen 1600×1000 gjennom sluttmålingen. Under høyere belastning kan den gradvis gå ned mot 1152×720 og opp igjen når det er margin.
- LOD-terskel justert, skygger på små ornamenter fjernet, dekorlys bak vegger skjules konservativt, og lommelyktas skyggeområde følger nærmeste strukturelle hindring med ekstra margin. Lysene prøves på nytt når kameraet flyttes eller en svak vegg knuses.

## Måling

Qualcomm Adreno X1-45, Direct3D 12, utgang 1920×1200. Ni kameravisninger, faktisk AI/fysikk og tent lommelykt; 180 oppvarmingsbilder og 180 målte bilder per visning, 60 FPS-grense. Testen hindrer at fienden fortsetter gjennom kameraet etter vanlig fangstavstand. Resultatene beskriver disse scenene etter oppvarming; de lover ikke at alle fremtidige scener eller første gangs shaderkompilering er uten hakk.

| Område | Median FPS | 95-persentil bildetid | GPU-tid |
|---|---:|---:|---:|
| cell | 60.1 | 16.92 ms | 11.90 ms |
| workshop | 60.1 | 16.87 ms | 7.90 ms |
| living | 60.1 | 17.20 ms | 11.50 ms |
| kitchen | 60.2 | 17.13 ms | 11.96 ms |
| doorway | 60.1 | 17.03 ms | 10.58 ms |
| stairs | 60.2 | 17.12 ms | 12.62 ms |
| master | 60.1 | 16.93 ms | 8.64 ms |
| east | 60.1 | 17.00 ms | 10.72 ms |
| landing | 60.1 | 17.16 ms | 10.86 ms |

Sluttmålingen er lagret i `docs/asset_optimization_performance.json`.

## Kontroll

Teksturstørrelser, mesh-indekser/LOD-indekser, adaptiv oppløsning, figurens basegeometri/beinvekter/blendformer, én gjenstand i hånden og slegge-/veggmekanikken er kontrollert. Lyskontrollen ble sammenlignet i seks faste visninger med og uten skjuling: fem identiske bilder; kjøkkenets gjennomsnittlige forskjell var 0,01 av 255 per kanal. Figur og jumpscare er også kontrollert visuelt med den nye rendereren.

Lukk og åpne Godot-editoren igjen for at editorens spillkjøring skal bruke den nye rendereren. En direkte oppstart av `project.godot` bruker de lagrede innstillingene.

Sikkerhetskopier av endrede importer, rendermesher, figur og innstillinger ligger i denne oppgavens `work/fps-pass/backup`.

Teknisk referanse: [Godot om 3D-oppløsningsskalering](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html), [Godot ImporterMesh og LOD](https://docs.godotengine.org/en/stable/classes/class_importermesh.html).
