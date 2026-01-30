# RUN FROM TERMINAL – Licență Analiza Piețelor Financiare

## 1) Intru în folderul proiectului (VS Code / Terminal)
```bash
cd ~/Desktop/Licenta_FMI
```

Verific că sunt în folderul corect:
```bash
ls
```

---

## 2) Verific că R este instalat
```bash
R --version
```

---

## 3) Instalez pachetele necesare (doar la prima rulare)
```bash
Rscript -e '
required_pkgs <- c("quantmod","xts","zoo","vars","glasso","igraph")
to_install <- required_pkgs[!required_pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install, repos="https://cloud.r-project.org")
'
```

---

## 4) Creez folderul de output (dacă nu există)
```bash
mkdir -p outputs
```

---

## 5) Rulez pipeline-ul COMPLET
(înlocuiește cu numele real al fișierului principal, dacă diferă)

```bash
Rscript main.R
```
sau
```bash
Rscript run_pipeline.R
```

---

## 6) Verific rezultatele generate
```bash
ls outputs
```

---

## 7) Deschid rezultatul principal (rețeaua)
macOS:
```bash
open outputs/network.png
```

Linux:
```bash
xdg-open outputs/network.png
```

---

## 8) Vizualizez rapid fișierele CSV
```bash
head outputs/centrality.csv
head outputs/top10_edges.csv
```

---

## Notă pentru prezentare
Întregul pipeline rulează din terminal folosind `Rscript`.
Toate rezultatele sunt exportate automat în folderul `outputs`.
