# NOTE PENTRU MINE – EXPLICAREA REZULTATELOR

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

---

## 7. Ce pun efectiv în lucrare (Word)

În capitolul „Rezultate empirice”:
- Figura: network.png
- Tabel: centrality.csv
- Tabel: top10_edges.csv
- Text explicativ (fără formule, focus pe interpretare)

Ideea-cheie:
nu descriu codul, ci **ce spun rezultatele despre piețe**.

---

## 8. În final

Rezultatele indică existența unei structuri clare a dependențelor condiționate
între sectoarele economiei americane, evidențiind sectoare centrale, legături directe
puternice și sectoare cu rol defensiv, cu implicații pentru transmiterea șocurilor
pe piețele financiare.
