# Skrekk-UI

scenes/horror/horror_ui.tscn er en egen CanvasLayer i husets hovedscene.
Overlay er en ColorRect som dekker skjermen og ignorerer musen.
Shaderen legger på mørkere kanter, en svak puls, lett filmstøy og sjeldne, korte
forstyrrelser. Den kopierer ikke skjermbildet og forskyver ikke kamera eller UV-er.

scripts/horror/horror_ui.gd justerer stemningen svakt i kjelleren og reagerer på
harde landinger. Inspector-feltene styrer styrken på vignett, filmstøy og puls.
rare_interference kan slås av. Materialet er unikt per instans.

L-bryteren i Lighting sender mode_changed. Vanlig lys skjuler overlayet og stopper
oppdateringen; skrekkmodus gjenoppretter effektene. Ingen ny tekst eller lyd legges til.

Test: tests/horror_ui_test.gd kontrollerer oppstart, ekte L-trykk begge veier,
at overlayet ikke fanger input, og den sjeldne forstyrrelsen.
