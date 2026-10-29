# The House – Godot horror

## Åpne på en annen PC

1. Installer Godot 4.7.2 (standardutgaven).
2. Logg inn med samme GitHub-konto i GitHub Desktop.
3. Velg File → Clone repository → herm0008888/horror-game og en lokal mappe.
4. I Godot Project Manager: Import → velg project.godot i mappen → Import & Edit.
5. Vent til Godot har importert modellene og teksturene. Trykk F5 for å spille.

Hovedscenen er `scenes/horror/test_area.tscn`. Huset er beholdt i `scenes/horror/main.tscn`.
Alle scripts, scener, materialer og teksturer følger med. Blender-kilden er
`assets/source/visitation_sculpt.blend`; spillet bruker den eksporterte GLB-filen,
så Blender er ikke nødvendig for å åpne og spille prosjektet.

## Kontroller

- WASD / piltaster: gå. Mus: se. Ctrl: snik.
- E: plukk opp lommelykten. F: slå den av/på.
- 1–5: bytt testsituasjon.
- R: start på nytt. Esc: slipp/fang musen.

## Jobb mellom to PC-er

Før du redigerer: klikk Fetch origin og eventuelt Pull origin i GitHub Desktop.
Etter redigering: lagre i Godot, skriv en kort beskrivelse i GitHub Desktop,
klikk Commit to main og deretter Push origin. Gjør dette før du bytter PC.
Godot sin `.godot`-mappe bygges automatisk og skal ikke lastes opp.

## Eksport

For å lage en Windows-spillfil: installer export templates for samme Godot-versjon
via Editor → Manage Export Templates. Bruk Windows Desktop-presetet og velg en
filplassering under `exports/`. Eksport er ikke nødvendig for å teste med F5.

## Oppdatering på en annen PC

Se [oppdateringsguiden](docs/SYNC_OTHER_PC.md). Åpne `project.godot` direkte fra Git-klonen etter Pull.
