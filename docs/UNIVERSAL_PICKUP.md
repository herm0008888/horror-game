# Løftbare møbler og dekor

- E: løft møbel eller småting du ser på (2,6 m rekkevidde).
- Q: slipp; objektet faller, velter og kolliderer med fysikk.
- Skap og skuffer: kort E åpner/lukker; hold E i 0,38 sekunder for å løfte hele møbelet.
- Store ting holdes lenger foran kameraet i vanlig størrelse og uten hvit markering. Småting under 0,65 m kan markeres.

PropInteraction er en egen node/scene i hovedscenen. Den oppdager authored asset_id-objekter, møbelscener og importerte modeller. Små modeller uten kollisjon får et usynlig interaksjonsområde; områder blokkerer ikke spilleren eller AI-ens sikt. Bygningens vegger, gulv og fast belysning er arkitektur.

Originalposisjoner, mesh, materialer og skapmekanikk beholdes. Fysikk opprettes først ved første løft, og holdes med hastighet/rotasjon fremfor teleportering. Dette lar ting kollidere under bæring og sove når de har landet, uten å aktivere hundrevis av møbler fra spillstart. Eksisterende rigidbodies og løse murbiter kan også løftes. Lommelykt og slegge bruker fortsatt sine egne håndfunksjoner.
