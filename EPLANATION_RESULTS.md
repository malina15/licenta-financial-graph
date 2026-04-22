# NOTE PENTRU MINE – EXPLICAREA REZULTATELOR

---

## DE CE AM ALES METODELE ASTEA? (explicat simplu)

### Problema de bază: cum măsori legăturile dintre sectoare?

Primul instinct ar fi să calculezi pur și simplu corelațiile dintre randamentele
sectoarelor. Problema e că dacă XLK și XLU sunt ambele corelate cu XLF, atunci
XLK și XLU vor părea corelate și între ele, chiar dacă nu au nicio legătură directă.
E ca și cum ai zice că două persoane sunt prieteni pentru că au un prieten comun.

Metodele alese rezolvă tocmai asta: separăm relațiile **directe** de cele **indirecte**.

---

### De ce VAR (Vector Autoregression)?

Piețele financiare au memorie: ce s-a întâmplat ieri influențează ce se întâmplă azi.
Dacă ignorăm asta și calculăm direct corelații pe randamente, amestecăm două lucruri:
- dependențe **în timp** (ce a mișcat ieri mișcă și azi)
- dependențe **contemporane** (ce se mișcă în același timp astăzi)

VAR(1) filtrează prima componentă. Practic, estimăm cât din mișcarea de azi a
fiecărui sector se explică prin mișcările de ieri ale tuturor sectoarelor. Ce rămâne
— reziduurile — reprezintă "surprizele" zilei respective, după ce am scos tot ce era
previzibil din trecut. Abia pe aceste reziduuri construim rețeaua.

**Pe scurt:** VAR pregătește datele pentru rețea, eliminând zgomotul dinamic.

---

### De ce Graphical LASSO (pentru rețeaua de corelații parțiale)?

Avem 11 sectoare. Covarianța reziduurilor e o matrice 11×11. Inversând-o obținem
matricea de precizie, care ne spune direct care perechi de sectoare mai sunt corelate
**după ce controlăm pentru toți ceilalți**. Asta e exact corelația parțială.

Problema: inversa eșantionului tinde să fie densă și instabilă când n nu e mult mai
mic decât T. Graphical LASSO adaugă o penalizare L1 care forțează unele intrări spre
zero — adică elimină legăturile slabe și păstrează doar pe cele puternice și directe.

Rezultatul este o rețea **rară**: nu toate sectoarele sunt conectate, doar cele cu
dependențe directe reale.

**Pe scurt:** GLASSO separă relațiile directe de cele indirecte și produce o rețea
interpretabilă.

---

### De ce rețeaua Granger (separată)?

Rețeaua de corelații parțiale ne arată **cine se mișcă împreună în același moment**.
Dar nu știm cine pe cine influențează în timp. Poate sectorul A mișcă sectorul B a
doua zi, sau invers.

Rețeaua Granger răspunde exact la asta. Testăm pentru fiecare pereche (A, B): "dacă
știu trecutul lui A, prezic mai bine viitorul lui B decât dacă nu îl știu?" Dacă da,
A Granger-cauzează B și adăugăm o săgeată A→B în rețea.

Rețeaua Granger este deci **direcționată** și spune cine transmite informație cui.

**Pe scurt:** Granger ne dă direcționalitate — cine influențează pe cine în timp.

---

### De ce rolling windows?

O singură rețea estimată pe toți cei 7 ani ascunde faptul că piața se schimbă.
Structura dependențelor din 2020 (criza COVID) e complet diferită față de 2019
(bull market) sau 2023 (rate ridicate). Rolling windows re-estimează rețeaua
în ferestre de un an care se deplasează lunar, dând o imagine dinamică.

**Pe scurt:** rolling windows transformă rețeaua dintr-un instantaneu static
într-un film al evoluției în timp.

---

### De ce sub-eșantioane (pre/COVID/post)?

Rolling windows dau multe ferestre greu de sintetizat. Sub-eșantioanele fixe
(pre-COVID, COVID, post-COVID) sunt mai ușor de interpretat economic: fiecare
perioadă are o logică proprie de piață și putem compara direct ierarhiile sectoriale
între ele.

**Pe scurt:** sub-eșantioanele dau context economic concret comparațiilor de rang.

---
---

## Maparea ETF-urilor la sectoare economice

| ETF  | Sector economic          |
|------|--------------------------|
| XLB  | Materials                |
| XLE  | Energy                   |
| XLF  | Financials               |
| XLI  | Industrials              |
| XLK  | Technology               |
| XLP  | Consumer Staples         |
| XLU  | Utilities                |
| XLV  | Health Care              |
| XLY  | Consumer Discretionary   |
| XLC  | Communication Services   |
| XLRE | Real Estate              |

---

## 1. Ce reprezintă rezultatele, în ansamblu

Rezultatele provin din aplicarea unui pipeline în doi pași:
1. **VAR(1)** pe randamentele zilnice ale celor 11 sectoare → extragere reziduuri
2. **Graphical LASSO** pe covarianța reziduurilor → matrice de precizie → rețea

Idea principală: rețeaua arată **dependențe condiționate între sectoare**, nu simple
corelații. Absența unei muchii înseamnă că, după ce controlăm pentru toate celelalte
sectoare, cele două nu mai au nicio relație directă.

---

## 2. Rețeaua de corelații parțiale (network.png)

Fișier: `outputs/network.png`

- fiecare nod = un sector economic
- fiecare muchie = dependență condiționată estimată prin graphical LASSO
- lipsa unei muchii = nu există legătură directă după ce controlez pentru restul

XLP (Consumer Staples) apare izolat (fără nicio muchie) la nivelul de regularizare
ales. Asta înseamnă că dependențele lui față de ceilalți sunt în totalitate indirecte,
ceea ce e consistent cu caracterul defensiv al sectorului.

---

## 3. Rețeaua de cauzalitate Granger (granger_network.png)

Fișier: `outputs/granger_network.png`

Rețea **direcționată**: o săgeată A→B înseamnă că valorile trecute ale lui A
ajută la predicția lui B, condiționat de restul.

- XLF (Financials): out-degree maxim (8) — transmite cel mai mult
- XLE (Energy): PageRank maxim — cel mai influențat de sectoarele importante
- XLU, XLRE, XLC: out-degree = 0 — nu Granger-cauzează pe nimeni

---

## 4. Centralitățile — eșantion complet

### 4.1 Rețeaua partial-corr (`centrality_partialcorr.csv`)

| Metrică       | #1      | #2      | #3      | Ultimul |
|---------------|---------|---------|---------|---------|
| Degree        | XLF (9) | XLK (8) | XLB (8) | XLU (2) |
| Strength      | XLK     | XLF     | XLY     | XLV     |
| Betweenness   | XLK     | XLRE    | XLY     | (mai mulți pe 0) |
| Closeness     | XLI     | XLY     | XLF     | XLV     |
| Eigenvector   | XLK     | XLF     | XLY     | XLU     |

XLK domină pe aproape toate dimensiunile. XLF are cel mai mare degree dar
XLK are conexiuni mai intense în medie.

### 4.2 Rețeaua Granger (`centrality_granger.csv`)

| Metrică       | #1         | #2      | #3      | Ultimul  |
|---------------|------------|---------|---------|----------|
| PageRank      | XLE (0.163)| XLV     | XLK     | XLU      |
| In-degree     | XLF/XLE/XLV/XLI (5) | — | —  | XLU/XLP (2) |
| Out-degree    | XLF/XLI/XLP (8) | —  | —       | XLU/XLRE/XLC (0) |
| Betweenness   | XLF (12)   | XLK (11)| XLY (10)| (mai mulți pe 0) |

XLE are PageRank maxim deși out-degree mic: e influențat de sectoare
centrale, nu el influențează pe alții. XLP surpriză: out-degree maxim
(transmite mult) deși e defensiv.

---

## 5. Ranking sectorial (outputs/rankings/)

### Fișiere principale
- `rank_partialcorr_full.csv` — ranguri 1–10 pe 5 metrici, rețea partial-corr
- `rank_granger_full.csv` — ranguri 1–11 pe 4 metrici, rețea Granger
- `heatmap_rank_partialcorr_full.png` — vizualizare completă ranking partial-corr
- `heatmap_rank_granger_full.png` — vizualizare completă ranking Granger

### Cum citesc heatmap-ul
Celulă mai închisă = rang mai bun (mai mic). Numărul din celulă = poziția exactă.
Sectoarele sunt ordonate de sus în jos de la cel mai slab la cel mai bun pe ansamblu.

---

## 6. Analiza pe sub-eșantioane

### Perioadele definite
- **Pre-COVID**: iun 2018 – dec 2019 (T=386 obs) — expansiune stabilă
- **COVID**: ian 2020 – dec 2021 (T=505 obs) — criză + recuperare
- **Post-COVID**: ian 2022 – ian 2026 (T=1016 obs) — normalizare, rate ridicate

### Ce s-a schimbat la partial-corr (strength)?

| Perioadă    | #1   | #2   | #3   |
|-------------|------|------|------|
| Pre-COVID   | XLK  | XLC  | XLY  |
| COVID       | XLF  | XLI  | XLK  |
| Post-COVID  | XLY  | XLK  | XLC  |

XLF sare de la rangul 5 la locul 1 în criză: sectorul financiar devine centrul
de greutate al rețelei de co-mișcări în momentele de stres.

### Ce s-a schimbat la Granger (PageRank)?

| Perioadă    | #1   | #2   | #3   |
|-------------|------|------|------|
| Pre-COVID   | XLF  | XLV  | XLE  |
| COVID       | XLF  | XLV  | XLI  |
| Post-COVID  | XLU  | XLP  | XLV  |

Rotația post-COVID e spectaculoasă: XLU urcă de la rangul 5 la #1, XLP de la
rangul 5 la #2. Sectoarele defensive (sensibile la dobânzi) devin cele mai
"prezise" de restul pieței în contextul ciclului monetar restrictiv.

---

## 7. Rolling window extins

### Fișiere produse
- `outputs/time_windows/rolling_partialcorr_extended.csv` — degree, strength,
  betweenness, eigenvector per fereastră (79 ferestre × 11 sectoare)
- `outputs/time_windows/rolling_granger_extended.csv` — indegree, outdegree,
  betweenness, PageRank per fereastră

### Grafice principale
- `rolling_pc_strength.png` — spike clar în jur de COVID crash (mar 2020):
  toate sectoarele devin mai interconectate simultan
- `rolling_gr_outdegree.png` — XLF și XLI au outdegree maxim în fereastra COVID
- `rolling_gr_pagerank.png` — XLF și XLV constanți la top, XLU crește după 2022

---

## 8. Cel mai puternice muchii (top10_edges.csv)

Fișier: `outputs/top10_edges.csv`

Conține perechile de sectoare cu cele mai mari corelații parțiale absolute.
Aceste perechi au dependențe directe puternice chiar și după ce controlăm
pentru tot restul sistemului.

---

## 9. Selectia parametrului rho (glasso_density_curve.png)

Fișier: `outputs/glasso_density_curve.png`

Pe măsură ce rho crește, rețeaua devine mai rară (mai puține muchii).
Am ales rho = 1.0, valoare care produce o rețea interpretabilă: suficient
de rară pentru a fi lizibilă, suficient de densă pentru a surprinde structura
reală a dependențelor.

---

## 10. Validarea modelului VAR

Fișiere: `outputs/var_stability_cusum.png`, `outputs/var_diagnostics_results.rds`

- Toate valorile proprii ale matricei A1 au modulul < 1 → VAR stabil ✓
- Testul Portmanteau: fără autocorelare reziduală semnificativă ✓
- Efecte ARCH prezente (heteroscedasticitate) — normal pentru serii financiare,
  nu invalidează analiza de rețea

---

## 11. Comparația celor două rețele — rezumat

| Aspect           | Partial-corr (GLASSO) | Granger               |
|------------------|-----------------------|-----------------------|
| Tip              | Nedirecționată        | Direcționată          |
| Ce măsoară       | Co-mișcări simultane  | Cauzalitate predictivă|
| Dominant eșantion complet | XLK, XLF    | XLE (PR), XLF (hub)   |
| Perioadă criză   | XLF devine #1         | XLF rămâne stabil     |
| Post-COVID       | XLY preia liderul     | XLU, XLP urcă la vârf |
| Cel mai periferic| XLU, XLV              | XLU (outdegree=0)     |

Un sector poate fi central într-o rețea și periferic în cealaltă: XLRE e
pe locul 2 la betweenness în partial-corr dar pe locul 7 la PageRank în Granger.
Cele două rețele sunt complementare, nu redundante.
