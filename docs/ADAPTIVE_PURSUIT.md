# Adaptiv forfølgelse

Kroppens flesh/cloth-materiale bruker nå meshens UV-koordinater. Prosjektering fra skjelettdeformerte VERTEX/NORMAL-posisjoner er fjernet, slik at mønsteret ikke glir når armer og kropp animeres.

HouseNavigation har eget dynamic_house_navigation.gd-script. Det oppdaterer gangrutene fra de aktuelle kollisjonene ved oppstart, flyttede store møbler, løft/slipp og dører/ødelagte vegger. Geometrien tas fra kollisjonsformer, og selve bakingen kjører på bakgrunnstråd. Oppdateringer samles etter litt ro og har en minste pause; huset bakes ikke hvert bilde. Den gamle fungerende ruten brukes til en ny er klar. Ting som bæres, små løse gjenstander og hengslede paneler blokkerer ikke nettet permanent.

Små løse ting som potter blir skjøvet til side og ignoreres av fiendens kropp ved kontakt, slik at de ikke kan bli en falsk etasje hun står fast på. Fangstavstanden er 1,45 m horisontalt og 1,1 m høydeforskjell, med siktprøver mot kroppen som fortsatt blokkeres av vegger og gitter.

Kontrollert: ny rute rundt en flyttet sofa, fangst uten kroppsoverlapping, vegg som blokkerer fangst, ned fra potte og videre jakt, UV på alle kroppsoverflater, opp/ned begge trapper og begge møbelrutene.
