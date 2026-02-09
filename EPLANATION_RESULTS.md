# NOTE PENTRU MINE – EXPLICAREA REZULTATELOR

## Maparea ETF-urilor la sectoare economice

În cadrul analizei sunt utilizate ETF-uri sectoriale americane, fiecare
corespunzând unui sector distinct al economiei. În continuare este prezentată
maparea dintre acronimele ETF-urilor și sectoarele economice aferente:

| ETF | Sector economic |
|-----|-----------------|
| XLB | Materials |
| XLE | Energy |
| XLF | Financials |
| XLI | Industrials |
| XLK | Technology |
| XLP | Consumer Staples |
| XLU | Utilities |
| XLV | Health Care |
| XLY | Consumer Discretionary |
| XLC | Communication Services |
| XLRE | Real Estate |

În toate figurile și tabelele ulterioare, nodurile sunt etichetate folosind
acronimele ETF-urilor corespunzătoare sectoarelor din acest tabel.


## 1. Ce reprezintă rezultatele, în ansamblu

Rezultatele provin din aplicarea următorului pipeline:
- date zilnice din Yahoo Finance (sectoare SUA)
- estimare VAR
- extragere reziduuri și matrice de covarianță
- graphical lasso → matrice de precizie (Theta)
- transformare în rețea (igraph)

Ideea principală:
rețeaua arată **dependențe condiționate între sectoare**, nu simple corelații.

---

## 2. Rețeaua (network.png)

Fișier:
outputs/network.png

Ce reprezintă:
- fiecare nod = un sector economic
- fiecare muchie = o dependență condiționată estimată prin graphical lasso
- lipsa unei muchii = nu există legătură directă după ce controlez pentru restul

Muchiile apar doar atunci când dependența condiționată dintre două sectoare este diferită de zero în matricea de precizie obținută prin graphical lasso. Astfel, sunt eliminate relațiile indirecte, iar rețeaua reflectă exclusiv legături directe între sectoare, după ce se controlează pentru influența tuturor celorlalte.


Rețeaua are o densitate redusă, ceea ce indică faptul că doar anumite sectoare
sunt direct conectate între ele.

Interpretare:
- structura rețelei sugerează canale de transmitere a șocurilor între sectoare
- nu toate sectoarele sunt la fel de importante

Se observă că sectorul utilităților (XLS) apare izolat în rețea, fără muchii. Acest rezultat indică faptul că, după ce se controlează pentru celelalte sectoare, XLS nu prezintă dependențe directe semnificative. Relațiile sale cu restul pieței sunt în mare parte indirecte, ceea ce este consistent cu caracterul defensiv al sectorului utilităților.

---

## 3. Centralitățile (centrality.csv)

Fișier:
outputs/centrality.csv

Ce conține:
- degree: numărul de conexiuni ale fiecărui sector
- strength_abs: intensitatea totală a legăturilor

Unele sectoare apar mai centrale în rețea, având atât mai multe conexiuni,
cât și legături mai puternice.

Interpretare economică:
- sectoarele centrale pot avea un rol important în propagarea riscurilor
- tehnologia și financiarul tind să fie mai influente

### 3.1 Observație privind interpretarea centralităților

Este important de subliniat că măsurile de centralitate calculate pentru această rețea reflectă
importanța sectoarelor în structura **dependențelor contemporane directe**, estimate pe baza
corelațiilor parțiale ale reziduurilor VAR.

Prin urmare, centralitatea ridicată a unor sectoare (precum tehnologia sau financiarul)
nu implică în mod necesar un rol cauzal în timp, ci indică o poziție structurală
importantă în rețeaua de co-mișcări condiționate ale pieței.

---

## 4. Cele mai puternice legături (top10_edges.csv)

Fișier:
outputs/top10_edges.csv

Ce reprezintă:
- cele mai mari valori absolute ale dependențelor condiționate
- legături directe între perechi de sectoare

Aceste perechi de sectoare sunt strâns conectate chiar și după ce ținem cont
de toate celelalte sectoare din economie.

Interpretare:
- aceste legături pot reflecta relații structurale sau economice reale
- sunt utile pentru discuții concrete în lucrare

---

## 5. Alegerea parametrului de regularizare (glasso_density_curve.png)

Fișiere:
outputs/glasso_density_curve.png
outputs/glasso_density_grid.csv

Ce reprezintă:
- cum se schimbă densitatea rețelei în funcție de parametrul rho
- ajută la alegerea unei rețele nici prea dense, nici prea rare

Am ales parametrul de regularizare astfel încât rețeaua să fie interpretabilă
și stabilă, evitând supra-conectarea.

---

## 6. Validarea modelului VAR

Fișiere:
outputs/var_stability_cusum.png
outputs/var_diagnostics_results.rds
logs/02_var_diagnostics_*.txt

Ce reprezintă:
- verificări de stabilitate și ipoteze pentru VAR
- justifică folosirea reziduurilor în graphical lasso

Am verificat stabilitatea și proprietățile reziduurilor VAR înainte de a construi
rețeaua, pentru a asigura corectitudinea rezultatelor.

## 6.1 Rețeaua de cauzalitate Granger

Pe lângă rețeaua bazată pe corelații parțiale, a fost construită și o a doua rețea
financiară pe baza **cauzalității Granger**, utilizând coeficienții modelului VAR estimat.

În această rețea:
- fiecare nod reprezintă un sector economic;
- o muchie orientată de la sectorul *i* către sectorul *j* indică faptul că
valorile trecute ale sectorului *i* contribuie semnificativ la predicția sectorului *j*,
condiționat de restul sectoarelor din sistem.

Această abordare permite identificarea **canalelor dinamice de transmitere a informației**
între sectoare, spre deosebire de rețeaua de corelații parțiale, care surprinde doar
interdependențe contemporane.

### Centralități în rețeaua Granger

Pentru rețeaua de cauzalitate Granger au fost calculate măsuri de centralitate specifice
rețelelor direcționate, incluzând indegree, outdegree, betweenness și PageRank.

Conform scorului PageRank, cele mai centrale trei sectoare sunt:
- XLE (Energy),
- XLV (Health Care),
- XLK (Technology).

Sectorul energetic (XLE) apare ca nod dominant al rețelei Granger, sugerând un rol important
în propagarea dinamică a șocurilor în timp. Sectorul sănătății (XLV) ocupă o poziție de
intermediere, în timp ce sectorul tehnologic (XLK) se remarcă printr-un outdegree ridicat,
indicând un rol activ în inițierea relațiilor cauzale către alte sectoare.

---

## 7. Ce pun efectiv în lucrare (Word)

În capitolul „Rezultate empirice”:
- Figura: network.png
- Tabel: centrality.csv
- Tabel: top10_edges.csv
- Text explicativ (fără formule, focus pe interpretare)

Ideea-cheie:
nu descriu codul, ci **ce spun rezultatele despre piețe**.

## 7.1 Comparația dintre cele două tipuri de rețele

Cele două rețele analizate surprind aspecte complementare ale interdependențelor
sectoriale pe piața financiară.

Rețeaua bazată pe corelații parțiale evidențiază **structura contemporană** a relațiilor
directe dintre sectoare, identificând noduri central importante din punct de vedere
structural.

În schimb, rețeaua de cauzalitate Granger surprinde **mecanismele dinamice de transmitere
în timp**, evidențiind sectoare care joacă un rol activ în influențarea evoluțiilor
ulterioare ale altor sectoare.

Diferențele dintre cele două structuri subliniază faptul că un sector poate fi central
din punct de vedere structural fără a fi neapărat dominant în sens cauzal, și invers.

## 7.2 Time windowing (rețea dinamică)

Pentru a analiza dacă structura interdependențelor dintre sectoare este stabilă în timp,
am extins analiza printr-o abordare de tip **rolling window**. Datele au fost împărțite
în ferestre glisante de aproximativ un an bursier (252 observații), cu pas lunar (~21 zile).

Pentru fiecare fereastră s-a repetat același pipeline utilizat în analiza principală:
estimarea unui model VAR(1), extragerea reziduurilor, estimarea matricei de precizie prin
graphical lasso (cu aceeași regularizare), construirea rețelei de corelații parțiale și
calculul centralității (strength_abs).

Rezultatul final este un set de valori ale centralității în timp, salvat în:
`outputs/time_windows/centrality_strength_over_time.csv`. Acesta permite urmărirea
evoluției rolului fiecărui sector în rețea și evidențiază faptul că importanța relativă
a sectoarelor poate varia între perioade, sugerând o structură dinamică a pieței.

---

## 8. În final

Rezultatele indică existența unei structuri clare a dependențelor condiționate
între sectoarele economiei americane, evidențiind sectoare centrale, legături directe
puternice și sectoare cu rol defensiv, cu implicații pentru transmiterea șocurilor
pe piețele financiare.