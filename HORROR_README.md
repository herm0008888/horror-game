# THE HOUSE — PSX horror

Åpne project.godot og trykk F5. Ny hovedscene: scenes/horror/main.tscn.
WASD / piler: gå. Mus: se. Shift: løp. Ctrl: snik.
E: åpne/lukke dører. F: lommelykt. R: start på nytt.
Escape: slipp/fang mus. Klikk i vinduet for å fange musen igjen.

Utforsk et råttent hus med to etasjer. Figuren vandrer i huset, ser og hører deg,
åpner dører og følger etter deg. Snik forbi, skjul deg bak vegger og bryt siktlinjen.
Blir du tatt, starter du igjen automatisk. Ingen inventory eller item-puslespill.

PSX-uttrykk: 640x360, nærmeste teksturfiltrering, små grunge-teksturer,
vertex-snapping, affine UV-er, kvantiserte farger, tåke, filmstøy og vignett.
Alt husinnhold har lagrede posisjoner i scenes/horror/house.tscn.
Dører, møbler, spiller, fiende og patruljeruter har egne scener.
Patruljepunktene er Marker3D-noder med forbindelser i metadata/links.
Fiendekilden finnes i assets/source/visitation_sculpt.blend.

Dette er et nytt, originalt hus og en original figur inspirert av sjangeren.
Ingen Granny-modeller, lyder eller teksturer er brukt.
Bilspillets tidligere scener og filer er beholdt separat.

Ingen hopping. Litt lysere ambientlys og mindre taake gir bedre oversikt.
Vegger har trepanel, gulv har gulvplanker og etasjeskillere har pusset
underside. Materialenes stoerrelse og aarringretning foelger overflatene.
Moebler har eik, sengetoey har vevd stoff, komfyren har emalje/metall
og kjoekkenbenken har keramiske fliser.
