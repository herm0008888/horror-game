# Kamera, bæring og atmosfære

Player/PlayerFeel har egne CameraMotion- og PickupController-noder. Kameraet har gangebobbing, pust, lett sidehelling, myk pitch og musesvai, landing og en liten FOV-endring. Z/C lener hodet; en kollisjonssjekk hindrer manuell leaning inn i vegger. Lommelyktmodellen svaier litt separat. Ingen hopping eller sprint er lagt til.

Små gjenstander tas med E som før. Store gjenstander krever 0,95 sekunder, svært store 1,2 sekunder. Hvit fremdrift tegnes rundt crosshairen kun mens E holdes mot samme gjenstand. Slipp E, se bort, gå ut av rekkevidde, trykk Esc eller bytt vindu for å avbryte. Kort E på en skapdør åpner/lukker den. Q slipper det som bæres. Store møbler senker gangfarten litt og følger kameraet med mer fysisk treghet. Store ting får ikke highlight.

HouseParticles er en egen, redigerbar scene med fem støvemitters og to myke damp/røykemitters i kjelleren. Materialer og posisjoner er lagret som ressurser/noder. Totalt 500 GPU-partikler, delte materialer, ingen partikkellys eller skyggekasting. Ingen ny fullskjerm blur eller kameraeffekt som flytter teksturene.

Test: res://tests/pickup_input_test.gd. Kontrollerer skjult ring i hvile, holdetid, avbrudd, skap, ferdig løft, kamera og partikkeloppsett. Renderer og hvit ring er også visuelt kontrollert i spillvindu.

R�yken f�lger ovnens utl�p ogs� om ovnen flyttes.
