# Analiza piețelor financiare folosind metode grafice

Acest proiect analizează interdependențele dintre principalele sectoare ale economiei americane
utilizând un cadru econometric VAR și metode de rețea bazate pe graphical lasso.

## Date
- Date zilnice pentru ETF-uri sectoriale din SUA
- Sursa: Yahoo Finance
- Perioada analizată: 2018-06-20 – 2026-01-21
- Frecvență: zilnică
- Datele sunt transformate în randamente logaritmice

## Pipeline metodologic

1. Descărcarea datelor financiare din Yahoo Finance și calculul randamentelor logaritmice
2. Estimarea unui model VAR (Vector Autoregressive) folosind pachetul `vars`
3. Extragerea matricei de covarianță a reziduurilor VAR
4. Estimarea matricei de precizie folosind graphical lasso
5. Selectarea parametrului de regularizare (rho) pe baza criteriului BIC
6. Construirea unei rețele financiare utilizând pachetul `igraph`
7. Analiza structurii rețelei și a centralității sectoarelor

## Output-uri
- Matricea de precizie estimată (Theta)
- Lista muchiilor și ponderilor rețelei
- Măsuri de centralitate pentru fiecare sector
- Vizualizarea rețelei financiare
