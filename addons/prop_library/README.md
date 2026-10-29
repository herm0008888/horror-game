# Møbelbibliotek

Åpne fanen **Møbelbibliotek** i høyre dokk i Godot. Søk etter navn/type, velg kategori eller bruk stjernen for favoritter. Klikk på et kort for større bilde og mål. Dra kortet inn i 3D-visningen eller scenetreet. Godot oppretter en vanlig sceneinstans med standard flytt/rotasjon/skalering og Ctrl+Z. Dobbeltklikk åpner objektets egen scene. Vis fil finner scenen i filpanelet.

Biblioteket inneholder 72 eksisterende modeller og lokale renderbilder. Ferdige interaktive skap/skuffer/komfyr bruker prosjektets eksisterende scener. De andre modellene har egne scener under props/, med nullpunkt på undersiden og bevarte kildeenheter. Større faste møbler har kollisjoner; små dekorobjekter er visuelle. Modellressurser gjenbrukes fra assets/house_library, kollisjonsressurser lagres komprimert. Alt er lokalt, uten nedlasting ved oppstart. Favoritter lagres lokalt i .godot/editor/prop_library.cfg.

Pluginen er aktivert i project.godot. Hvis prosjektet allerede var åpent da pluginen ble installert: last prosjektet på nytt, eller aktiver **Møbelbibliotek** i Project Settings → Plugins. Deaktivering fjerner bare panelet; plasserte modeller blir igjen.

Pluginen bygger ikke navigasjonsnettet automatisk. Når du endrer rommets møblering, bak NavigationRegion3D på nytt, slik at fienden bruker den oppdaterte plasseringen.
