# RUNBOOK — Licență: Analiza Rețelelor Financiare Sectoriale

Ghid complet de rulare a pipeline-ului de la zero, în ordine. Fiecare pas produce
fișierele de care depinde pasul următor. Nu sar pași.

---

## 0. Pregătire inițială

### Intru în folderul proiectului
```bash
cd ~/Desktop/Licenta_FMI
```

Verific că sunt în locul corect:
```bash
ls
# ar trebui să văd: R/  data/  outputs/  thesis/  RUNBOOK.md  etc.
```

### Instalez pachetele R necesare (doar la prima rulare)
```bash
Rscript -e '
pkgs <- c(
  "quantmod", "xts", "zoo",
  "vars", "glasso", "igraph",
  "car", "ggplot2", "tidyr"
)
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0)
  install.packages(to_install, repos = "https://cloud.r-project.org")
cat("Toate pachetele sunt disponibile.\n")
'
```

---

## Pipeline complet — rulare în ordine

### Script 1 — Descărcare date
```bash
Rscript R/00_download_data.R
```
**Produce:** `outputs/prices_sectors.rds`, `outputs/returns_sectors.rds`, `outputs/returns.rds`

---

### Script 2 — Model VAR(1) + rețeaua de corelații parțiale (glasso)
```bash
Rscript R/01_var_glasso_network.R
```
**Produce:**
- `outputs/var_fit.rds` — modelul VAR estimat
- `outputs/var_residuals.rds`, `outputs/var_residual_cov_S.csv`
- `outputs/glasso_precision_Theta.csv` — matricea de precizie
- `outputs/partial_correlations.csv`, `outputs/edges.csv`, `outputs/top10_edges.csv`
- `outputs/network.png` — rețeaua de corelații parțiale vizualizată

---

### Script 3 — Diagnostice VAR
```bash
Rscript R/02_var_diagnostics.R
```
**Produce:** `outputs/var_stability_cusum.png`, `outputs/var_diagnostics_results.rds`

---

### Script 4 — Selectia parametrului de regularizare rho (glasso)
```bash
Rscript R/03_glasso_selection.R
```
**Produce:** `outputs/glasso_density_curve.png`, `outputs/glasso_density_grid.csv`

---

### Script 5 — Rețeaua de cauzalitate Granger
```bash
Rscript R/04_granger_network.R
```
**Produce:** `outputs/granger_edges.csv`, `outputs/granger_network.png`

---

### Script 6 — Măsuri de centralitate (ambele rețele)
```bash
Rscript R/05_centrality_measures.R
```
**Produce:**
- `outputs/centrality_partialcorr.csv` — degree, strength, betweenness, closeness, eigenvector
- `outputs/centrality_granger.csv` — indegree, outdegree, betweenness, PageRank
- `outputs/top3_partialcorr.csv`, `outputs/top3_granger.csv`

---

### Script 7 — Analiză rolling window (rețeaua partial-corr, strength de bază)
```bash
Rscript R/06_time_window_network.R
```
**Produce:** `outputs/time_windows/centrality_strength_over_time.csv`

---

### Script 8 — Sumar rolling window în Markdown
```bash
Rscript R/07_write_time_window_summary_md.R
```
**Produce:** `time_window_summary.md`

---

### Script 9 — Ranking sectorial + sub-eșantioane + rolling extins
```bash
Rscript R/08_sector_rankings.R
```
⚠️ Durează ~5–10 minute (79 ferestre × testele Granger).

**Produce în `outputs/rankings/`:**
- `rank_partialcorr_full.csv`, `rank_granger_full.csv` — ranking eșantion complet
- `rank_partialcorr_{pre_covid,covid,post_covid}.csv` — ranking per perioadă
- `rank_granger_{pre_covid,covid,post_covid}.csv` — ranking Granger per perioadă
- `heatmap_rank_partialcorr_full.png`, `heatmap_rank_granger_full.png`
- `heatmap_sub_pc_strength.png`, `heatmap_sub_pc_eigenvector.png`
- `heatmap_sub_gr_pagerank.png`, `heatmap_sub_gr_outdegree.png`
- `lollipop_pc_*.png` (5 fișiere), `lollipop_gr_*.png` (4 fișiere)
- `rolling_pc_*.png` (4 fișiere), `rolling_gr_*.png` (3 fișiere)

**Produce în `outputs/time_windows/`:**
- `rolling_partialcorr_extended.csv` — degree, strength, betweenness, eigenvector per fereastră
- `rolling_granger_extended.csv` — indegree, outdegree, betweenness, PageRank per fereastră

---

## Compilare teză PDF

```bash
cd thesis
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
open main.pdf
```

---

## Verificare rapidă a rezultatelor cheie

```bash
# Ranking eșantion complet — partial-corr
cat outputs/rankings/rank_partialcorr_full.csv

# Ranking eșantion complet — Granger
cat outputs/rankings/rank_granger_full.csv

# Top 3 pe fiecare rețea
cat outputs/top3_partialcorr.csv
cat outputs/top3_granger.csv

# Deschid heatmap-ul de ranking principal
open outputs/rankings/heatmap_rank_partialcorr_full.png
open outputs/rankings/heatmap_rank_granger_full.png

# Deschid graficele de evoluție temporală
open outputs/rankings/rolling_pc_strength.png
open outputs/rankings/rolling_gr_pagerank.png
```

---

## Structura completă a folderului outputs/

```
outputs/
├── returns.rds                          # date de intrare (randamente zilnice)
├── var_fit.rds                          # model VAR(1) estimat
├── edges.csv                            # muchii rețea partial-corr
├── granger_edges.csv                    # muchii rețea Granger
├── centrality_partialcorr.csv           # centralități partial-corr
├── centrality_granger.csv               # centralități Granger
├── network.png                          # vizualizare rețea partial-corr
├── granger_network.png                  # vizualizare rețea Granger
├── glasso_density_curve.png             # selectie rho
├── var_stability_cusum.png              # diagnostice VAR
├── rankings/
│   ├── rank_partialcorr_full.csv        # ranking complet partial-corr
│   ├── rank_granger_full.csv            # ranking complet Granger
│   ├── rank_*_{pre_covid,covid,post_covid}.csv
│   ├── heatmap_rank_*.png               # heatmap-uri ranking
│   ├── heatmap_sub_*.png                # heatmap-uri comparative pe perioade
│   ├── lollipop_*.png                   # valori brute per metrică
│   └── rolling_*.png                    # evoluție temporală centralitate
└── time_windows/
    ├── centrality_strength_over_time.csv        # rolling original (strength)
    ├── rolling_partialcorr_extended.csv         # rolling extins partial-corr
    └── rolling_granger_extended.csv             # rolling extins Granger
```
