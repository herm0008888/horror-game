# Oppdater prosjektet på den andre PC-en

Dette repoet er nå synkronisert med det aktive Godot-prosjektet på den første PC-en.
Hent hele oppdateringen, ikke bare house_layout.tscn. Scener, scripts, shaderfiler,
modeller, teksturer, .uid-filer og importinnstillinger hører sammen.

## Med GitHub Desktop

1. Lukk spillet og Godot før du oppdaterer.
2. Velg horror-game i GitHub Desktop.
3. Har du lokale endringer: lagre dem i en commit eller stash dem før Pull.
4. Trykk Fetch origin og deretter Pull origin.
5. Velg Repository > Show in Explorer.
6. Importer/åpne project.godot fra akkurat denne repo-mappen i Godot 4.7.2.
7. La første import fullføres, og start hovedscenen med F6 eller spillet med F5.

Hvis Godot fortsatt viser det gamle spillet, bruker du sannsynligvis en annen
prosjektmappe. Begge PC-ene bør redigere direkte i sin lokale horror-game-klone.
Da oppdaterer Pull også filene som Godot faktisk åpner. Du skal ikke manuelt
kopiere noen utvalgte scener fra Downloads til et eldre prosjekt.

## Med Git

Kjør i den lokale horror-game-klonen, etter at egne endringer er lagret:

    git switch main
    git pull --ff-only origin main

Hvis Git melder konflikt eller divergent branches, stopp og behold lokale
endringer. Ikke bruk reset --hard for å løse dette uten å sikre arbeidet.

## Hva som følger med

- Hele det nåværende prosjektet og møbelbibliotek-pluginen.
- Skog, terreng, husfasade, inngangsdør og utendørs start.
- Oppdatert monster, AI/navigasjon, pickup-system, kamera, lys og effekter.
- Nødvendige kildeassets, teksturer, sceneavhengigheter og stabile UID-filer.
- Endringsliste i docs/LATEST_PC_SYNC.json.

.godot er lokal cache og blir laget på nytt. Eksporterte .exe/.pck og midlertidige
backupfiler er utelatt. Dette er en vanlig commit som bevarer tidligere historikk.

## Historien akkurat nå

Prosjektet inneholder fortsatt den tidligere Ida-historien og dens skogsti-start.
Den nylig avtalte historien med bilulykke, dyr i veien, mobil uten dekning og
hånd som drar bort støtten til gulvfella er ikke implementert ennå. Bil-, mobil-
og dyremodellene som bare er diskutert i chatten, er heller ikke importert.
Dette er derfor en opplasting av det faktiske nåværende prosjektet, ikke av
framtidige funksjoner.
