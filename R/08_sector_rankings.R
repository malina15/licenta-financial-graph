# =============================================================================
# 08_sector_rankings.R
#
# Calculez ranking-urile sectoriale pe baza statisticilor de rețea și analizez
# cum se schimbă centralitatea fiecărui sector în timp și pe sub-eșantioane.
# Fac asta pentru ambele tipuri de rețele: partial-corr (glasso, nedirectionată)
# și Granger (directionată). Structura scriptului:
#   1. Ranking pe eșantionul complet (din centralitățile deja calculate)
#   2. Heatmap-uri de ranking pentru ambele rețele
#   3. Lollipop charts cu valorile brute, per metrică
#   4. Funcții reutilizabile pentru re-estimare pe orice subset de date
#   5. Analiză pe sub-eșantioane fixe: pre-COVID / COVID / post-COVID
#   6. Heatmap-uri comparative pe sub-eșantioane
#   7. Rolling window extins — adaug și Granger, nu doar partial-corr
#   8. Grafice de evoluție temporală cu marcaje pentru evenimente economice
# =============================================================================

library(igraph)
library(vars)
library(glasso)
library(car)
library(xts)
library(ggplot2)
library(tidyr)

dir.create("outputs/rankings", showWarnings = FALSE, recursive = TRUE)

# Indexul din returns.rds este numeric (Unix timestamp în secunde).
# Definesc un utilitar de conversie pe care îl voi folosi în tot scriptul.
to_date <- function(x) as.Date(as.POSIXct(x, origin = "1970-01-01", tz = "UTC"))


# =============================================================================
# SECȚIUNEA 1: Ranking pe eșantionul complet
#
# Nu re-estimez rețelele — citesc centralitățile deja calculate în scripturile
# 05_centrality_measures.R și construiesc tabelele de rang.
# Atribui rang 1 sectorului cu valoarea cea mai mare (cel mai central).
# =============================================================================

cat("--- Secțiunea 1: Ranking eșantion complet ---\n")

# ---- 1a. Partial-corr (glasso) — rețea nedirectionată ----
cent_pc <- read.csv("outputs/centrality_partialcorr.csv", stringsAsFactors = FALSE)

# Construiesc tabelul de rang: pentru fiecare metrică sortez descrescător
# și atribui pozițiile 1...11. La egalitate, aleg rangul minim (ties.method = "min").
rank_table_pc <- data.frame(sector = cent_pc$node)
for (col in c("degree", "strength_abs", "betweenness", "closeness", "eigenvector")) {
  rank_table_pc[[col]] <- rank(-cent_pc[[col]], ties.method = "min")
}
rank_table_pc <- rank_table_pc[order(rank_table_pc$degree), ]

write.csv(rank_table_pc, "outputs/rankings/rank_partialcorr_full.csv", row.names = FALSE)
cat("Salvat: rank_partialcorr_full.csv\n")

# ---- 1b. Granger — rețea directionată ----
cent_gr <- read.csv("outputs/centrality_granger.csv", stringsAsFactors = FALSE)

rank_table_gr <- data.frame(sector = cent_gr$node)
for (col in c("indegree", "outdegree", "betweenness", "pagerank")) {
  rank_table_gr[[col]] <- rank(-cent_gr[[col]], ties.method = "min")
}
rank_table_gr <- rank_table_gr[order(rank_table_gr$pagerank), ]

write.csv(rank_table_gr, "outputs/rankings/rank_granger_full.csv", row.names = FALSE)
cat("Salvat: rank_granger_full.csv\n")

# Afișez tabelele în consolă ca să am o verificare rapidă
cat("\nRanking partial-corr:\n");  print(rank_table_pc)
cat("\nRanking Granger:\n");       print(rank_table_gr)


# =============================================================================
# SECȚIUNEA 2: Heatmap de ranking-uri — eșantion complet
#
# Vizualizez simultan cum se clasează fiecare sector pe toate dimensiunile.
# Culoarea mai închisă = rang mai bun (mai mic). Textul din celulă = rang exact,
# astfel că pot citi și numărul, nu doar gradientul de culoare.
# =============================================================================

cat("\n--- Secțiunea 2: Heatmap-uri ranking eșantion complet ---\n")

plot_rank_heatmap <- function(rank_df, title, filename, color_low = "#2166ac") {
  # Convertesc tabelul wide în format lung — necesar pentru ggplot
  df_long <- pivot_longer(rank_df, cols = -sector, names_to = "metric", values_to = "rank")
  n       <- nrow(rank_df)

  # Ordonez sectoarele pe axa y după rangul mediu, ca să iasă o ordine coerentă
  sector_order <- rank_df
  sector_order$mean_rank <- rowMeans(rank_df[, -1], na.rm = TRUE)
  sector_order <- sector_order[order(sector_order$mean_rank), "sector"]
  df_long$sector <- factor(df_long$sector, levels = sector_order)

  p <- ggplot(df_long, aes(x = metric, y = sector, fill = rank)) +
    geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = rank), color = "black", size = 4) +
    scale_fill_gradient(
      low    = color_low,
      high   = "#f7f7f7",
      limits = c(1, n),
      name   = "Rang\n(1 = cel mai\ncental)"
    ) +
    labs(title = title, x = "Metrică", y = "Sector ETF") +
    theme_minimal(base_size = 13) +
    theme(
      plot.title  = element_text(face = "bold", hjust = 0.5),
      axis.text.x = element_text(angle = 30, hjust = 1)
    )

  ggsave(filename, plot = p, width = 8, height = 5, dpi = 180)
  cat("Salvat:", filename, "\n")
}

plot_rank_heatmap(
  rank_table_pc,
  "Ranking sectoare — rețea partial-corr (eșantion complet)",
  "outputs/rankings/heatmap_rank_partialcorr_full.png",
  color_low = "#2166ac"
)

plot_rank_heatmap(
  rank_table_gr,
  "Ranking sectoare — rețea Granger (eșantion complet)",
  "outputs/rankings/heatmap_rank_granger_full.png",
  color_low = "#d6604d"
)


# =============================================================================
# SECȚIUNEA 3: Lollipop charts — valori brute per metrică
#
# Rangul îmi spune ordinea, dar nu magnitudinea diferențelor.
# Cu un lollipop chart ordonat descrescător văd și cât de departe este
# sectorul de top față de cel de la coadă — informație relevantă pentru
# interpretarea economică.
# =============================================================================

cat("\n--- Secțiunea 3: Lollipop charts ---\n")

plot_lollipop <- function(df, id_col, val_col, title, filename, color = "#2166ac") {
  df_s            <- df[order(df[[val_col]], decreasing = TRUE), ]
  df_s[[id_col]]  <- factor(df_s[[id_col]], levels = rev(df_s[[id_col]]))

  p <- ggplot(df_s, aes(x = .data[[id_col]], y = .data[[val_col]])) +
    geom_segment(
      aes(xend = .data[[id_col]], y = 0, yend = .data[[val_col]]),
      color     = color,
      linewidth = 1
    ) +
    geom_point(size = 4, color = color) +
    coord_flip() +
    labs(title = title, x = NULL, y = val_col) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))

  ggsave(filename, plot = p, width = 7, height = 4, dpi = 180)
  cat("Salvat:", filename, "\n")
}

# Partial-corr: generez câte un grafic pentru fiecare metrică
for (m in c("degree", "strength_abs", "betweenness", "closeness", "eigenvector")) {
  plot_lollipop(
    cent_pc, "node", m,
    paste0("Partial-corr — ", m, " (eșantion complet)"),
    paste0("outputs/rankings/lollipop_pc_", m, ".png"),
    color = "#2166ac"
  )
}

# Granger: același lucru
for (m in c("indegree", "outdegree", "betweenness", "pagerank")) {
  plot_lollipop(
    cent_gr, "node", m,
    paste0("Granger — ", m, " (eșantion complet)"),
    paste0("outputs/rankings/lollipop_gr_", m, ".png"),
    color = "#d6604d"
  )
}


# =============================================================================
# SECȚIUNEA 4: Funcții generice de re-estimare
#
# Definesc două funcții pe care le voi apela atât pentru sub-eșantioanele fixe
# cât și pentru ferestrele rolling. Parametrii sunt consistenți cu analiza
# principală: rho = 1.0 pentru glasso, alpha = 0.05 pentru testele Granger,
# VAR(1) în ambele cazuri (lag ales prin BIC în analiza principală).
# =============================================================================

# ---- compute_partialcorr_centrality ----------------------------------------
# Primesc o matrice de randamente Y (T x K), estimez VAR(1), extrag reziduurile,
# aplicăm glasso pe covarianța lor și calculez statisticile de centralitate
# pe graful de corelații parțiale rezultat.
compute_partialcorr_centrality <- function(Y, rho = 1.0) {
  vfit  <- VAR(Y, p = 1, type = "const")
  S     <- cov(residuals(vfit))
  gl    <- glasso(S, rho = rho)
  Theta <- gl$wi   # matricea de precizie estimată

  # Extrag corelațiile parțiale din matricea de precizie:
  # pcor_ij = -Theta_ij / sqrt(Theta_ii * Theta_jj)
  pcor <- -Theta / sqrt(outer(diag(Theta), diag(Theta)))
  diag(pcor) <- 0

  adj         <- (abs(Theta) > 1e-8) * 1
  diag(adj)   <- 0
  W           <- pcor
  W[adj == 0] <- 0

  g <- graph_from_adjacency_matrix(W, mode = "max", weighted = TRUE, diag = FALSE)
  V(g)$name <- colnames(Y)

  # Dacă penalizarea e prea mare și nu rămâne nicio muchie, returnez zerouri
  # pentru a nu genera erori în funcțiile igraph care nu acceptă grafuri goale
  if (ecount(g) == 0) {
    return(data.frame(
      sector      = colnames(Y),
      degree      = 0, strength    = 0,
      betweenness = 0, closeness   = 0, eigenvector = 0
    ))
  }

  # Distanța = 1/|w| — folosesc ponderi inverse pentru betweenness și closeness,
  # astfel că o conexiune puternică înseamnă o distanță mică (nodurile sunt "aproape")
  w_dist <- 1 / (abs(E(g)$weight) + 1e-8)

  data.frame(
    sector      = V(g)$name,
    degree      = as.numeric(degree(g)),
    strength    = as.numeric(strength(g, weights = abs(E(g)$weight))),
    betweenness = as.numeric(betweenness(g, directed = FALSE, weights = w_dist)),
    closeness   = as.numeric(closeness(g, normalized = TRUE, weights = w_dist)),
    eigenvector = as.numeric(eigen_centrality(g, directed = FALSE,
                                              weights = abs(E(g)$weight))$vector)
  )
}

# ---- compute_granger_centrality --------------------------------------------
# Estimez VAR(1) pe Y, testez cauzalitatea Granger pentru fiecare pereche
# (cause → effect) cu un test F (linearHypothesis), rețin muchiile semnificative
# la nivelul alpha și calculez centralitățile pe graful diriguit rezultat.
compute_granger_centrality <- function(Y, alpha = 0.05) {
  vars_n <- colnames(Y)
  vfit   <- VAR(Y, p = 1, type = "const")

  # La VAR(1) există un singur lag, deci ipoteza nulă pentru Granger este simplă
  make_h <- function(cause) paste0(cause, ".l1 = 0")

  edge_rows <- list()
  for (effect in vars_n) {
    eq <- vfit$varresult[[effect]]
    for (cause in vars_n) {
      if (cause == effect) next
      tst  <- tryCatch(
        car::linearHypothesis(eq, make_h(cause)),
        error = function(e) NULL
      )
      if (is.null(tst)) next
      pval <- tst$`Pr(>F)`[2]
      if (!is.na(pval) && pval < alpha)
        edge_rows[[length(edge_rows) + 1]] <-
          data.frame(from = cause, to = effect, weight = -log10(pval))
    }
  }

  # Dacă nicio pereche nu trece testul în această fereastră, returnez zerouri
  if (length(edge_rows) == 0) {
    n <- length(vars_n)
    return(data.frame(
      sector      = vars_n,
      indegree    = 0, outdegree   = 0,
      betweenness = 0, pagerank    = rep(1 / n, n)
    ))
  }

  edges_df    <- do.call(rbind, edge_rows)
  g           <- graph_from_data_frame(edges_df, directed = TRUE, vertices = vars_n)
  E(g)$weight <- edges_df$weight

  data.frame(
    sector      = V(g)$name,
    indegree    = as.numeric(degree(g, mode = "in")),
    outdegree   = as.numeric(degree(g, mode = "out")),
    betweenness = as.numeric(betweenness(g, directed = TRUE)),
    pagerank    = as.numeric(page_rank(g, directed = TRUE, weights = E(g)$weight)$vector)
  )
}


# =============================================================================
# SECȚIUNEA 5: Analiză pe sub-eșantioane fixe
#
# Definesc trei perioade cu relevanță economică clară: înainte de COVID,
# criza COVID și perioada post-COVID. Re-estimez complet rețelele pentru
# fiecare perioadă și calculez ranking-urile, astfel că pot observa
# dacă ierarhia sectorială se schimbă în funcție de regimul de piață.
# =============================================================================

cat("\n--- Secțiunea 5: Ranking pe sub-eșantioane ---\n")

returns_full <- readRDS("outputs/returns.rds")
dates_all    <- to_date(index(returns_full))
Y_all        <- coredata(returns_full)
colnames(Y_all) <- colnames(returns_full)

# Perioadele pe care le-am ales reflectă evenimente documentate în literatura
# financiară: șocul COVID din martie 2020 și revenirea graduală post-pandemie
sub_samples <- list(
  pre_covid  = list(start = "2018-06-20", end = "2019-12-31"),
  covid      = list(start = "2020-01-01", end = "2021-12-31"),
  post_covid = list(start = "2022-01-01", end = "2026-01-21")
)

subsample_ranks_pc <- list()
subsample_ranks_gr <- list()

for (pname in names(sub_samples)) {
  cat("\nEstimez sub-eșantionul:", pname, "...\n")

  per <- sub_samples[[pname]]
  idx <- which(dates_all >= as.Date(per$start) & dates_all <= as.Date(per$end))

  if (length(idx) < 60) {
    cat("  Prea puține observații (", length(idx), ") — sar.\n"); next
  }
  cat("  Observații:", length(idx), "\n")

  Y <- Y_all[idx, ]

  # -- Partial-corr --
  pc <- tryCatch(
    compute_partialcorr_centrality(Y),
    error = function(e) { cat("  Eroare pc:", e$message, "\n"); NULL }
  )
  if (!is.null(pc)) {
    for (col in c("degree", "strength", "betweenness", "closeness", "eigenvector"))
      pc[[paste0("rank_", col)]] <- rank(-pc[[col]], ties.method = "min")
    pc$period <- pname
    subsample_ranks_pc[[pname]] <- pc
    write.csv(pc,
      paste0("outputs/rankings/rank_partialcorr_", pname, ".csv"),
      row.names = FALSE)
    cat("  Salvat rank_partialcorr_", pname, ".csv\n", sep = "")
  }

  # -- Granger --
  gr <- tryCatch(
    compute_granger_centrality(Y),
    error = function(e) { cat("  Eroare gr:", e$message, "\n"); NULL }
  )
  if (!is.null(gr)) {
    for (col in c("indegree", "outdegree", "betweenness", "pagerank"))
      gr[[paste0("rank_", col)]] <- rank(-gr[[col]], ties.method = "min")
    gr$period <- pname
    subsample_ranks_gr[[pname]] <- gr
    write.csv(gr,
      paste0("outputs/rankings/rank_granger_", pname, ".csv"),
      row.names = FALSE)
    cat("  Salvat rank_granger_", pname, ".csv\n", sep = "")
  }
}


# =============================================================================
# SECȚIUNEA 6: Heatmap-uri comparative pe sub-eșantioane
#
# Acum că am ranking-urile per perioadă, le pun alăturat într-un heatmap
# ca să pot vedea dintr-o privire dacă un sector a urcat sau coborât în
# ierarhie între cele trei perioade. Ordonez sectoarele după media rangurilor
# ca să grupez natural sectoarele care rămân centrale vs. cele care fluctuează.
# =============================================================================

cat("\n--- Secțiunea 6: Heatmap-uri comparative pe sub-eșantioane ---\n")

plot_subsample_heatmap <- function(list_dfs, rank_col, title, filename, color_low) {
  if (length(list_dfs) < 2) {
    cat("  Prea puține perioade disponibile pentru heatmap:", title, "\n")
    return(invisible(NULL))
  }

  df_all  <- do.call(rbind, list_dfs)
  df_wide <- pivot_wider(
    df_all[, c("sector", "period", rank_col)],
    names_from  = "period",
    values_from = all_of(rank_col)
  )

  # Calculez media rangurilor și ordonez sectoarele după ea
  metric_cols        <- setdiff(colnames(df_wide), "sector")
  df_wide$mean_rank  <- rowMeans(df_wide[, metric_cols, drop = FALSE], na.rm = TRUE)
  df_wide            <- df_wide[order(df_wide$mean_rank), ]
  df_wide$mean_rank  <- NULL

  df_long        <- pivot_longer(df_wide, cols = -sector, names_to = "period", values_to = "rank")
  df_long$period <- factor(
    df_long$period,
    levels = c("pre_covid", "covid", "post_covid"),
    labels = c("Pre-COVID\n(2018-2019)", "COVID\n(2020-2021)", "Post-COVID\n(2022-2026)")
  )
  df_long$sector <- factor(df_long$sector, levels = unique(df_wide$sector))

  n <- length(unique(df_long$sector))

  p <- ggplot(df_long, aes(x = period, y = sector, fill = rank)) +
    geom_tile(color = "white", linewidth = 0.6) +
    geom_text(aes(label = rank), color = "black", size = 4.5) +
    scale_fill_gradient(low = color_low, high = "#f7f7f7", limits = c(1, n), name = "Rang") +
    labs(title = title, x = NULL, y = "Sector ETF") +
    theme_minimal(base_size = 13) +
    theme(
      plot.title  = element_text(face = "bold", hjust = 0.5),
      axis.text.x = element_text(angle = 15, hjust = 1)
    )

  ggsave(filename, plot = p, width = 7, height = 5, dpi = 180)
  cat("Salvat:", filename, "\n")
}

plot_subsample_heatmap(
  subsample_ranks_pc, "rank_strength",
  "Ranking după strength (partial-corr) pe sub-eșantioane",
  "outputs/rankings/heatmap_sub_pc_strength.png",
  color_low = "#2166ac"
)
plot_subsample_heatmap(
  subsample_ranks_pc, "rank_eigenvector",
  "Ranking după eigenvector centrality (partial-corr) pe sub-eșantioane",
  "outputs/rankings/heatmap_sub_pc_eigenvector.png",
  color_low = "#4393c3"
)
plot_subsample_heatmap(
  subsample_ranks_gr, "rank_pagerank",
  "Ranking după PageRank (Granger) pe sub-eșantioane",
  "outputs/rankings/heatmap_sub_gr_pagerank.png",
  color_low = "#d6604d"
)
plot_subsample_heatmap(
  subsample_ranks_gr, "rank_outdegree",
  "Ranking după out-degree (Granger) pe sub-eșantioane",
  "outputs/rankings/heatmap_sub_gr_outdegree.png",
  color_low = "#f4a582"
)


# =============================================================================
# SECȚIUNEA 7: Rolling window extins — adaug Granger în timp
#
# Scriptul 06_time_window_network.R calculează doar strength pentru partial-corr.
# Extind acum la: degree, strength, betweenness, eigenvector (partial-corr)
# și indegree, outdegree, betweenness, pagerank (Granger).
#
# Avertisment computațional: testele F Granger sunt costisitoare.
# 79 ferestre × 11 × 10 perechi = ~8700 teste F. Pe hardware obișnuit
# estimez ~5-10 minute. Adaug un contor de progres ca să urmăresc avansul.
# =============================================================================

cat("\n--- Secțiunea 7: Rolling window extins ---\n")

window_size <- 252   # ~1 an bursier (consistent cu 06_time_window_network.R)
step_size   <- 21    # ~1 lună
n_total     <- nrow(Y_all)
n_windows   <- floor((n_total - window_size) / step_size) + 1

results_pc_rw <- list()
results_gr_rw <- list()
counter       <- 1

cat("Total ferestre de estimat:", n_windows, "\n")

for (start_idx in seq(1, n_total - window_size, by = step_size)) {

  end_idx      <- start_idx + window_size - 1
  Y            <- Y_all[start_idx:end_idx, ]
  colnames(Y)  <- colnames(Y_all)
  window_dates <- dates_all[start_idx:end_idx]
  w_start      <- as.character(min(window_dates))
  w_end        <- as.character(max(window_dates))

  # -- Partial-corr --
  pc_rw <- tryCatch(compute_partialcorr_centrality(Y), error = function(e) NULL)
  if (!is.null(pc_rw)) {
    pc_rw$window_start <- w_start
    pc_rw$window_end   <- w_end
    results_pc_rw[[counter]] <- pc_rw
  }

  # -- Granger --
  gr_rw <- tryCatch(compute_granger_centrality(Y), error = function(e) NULL)
  if (!is.null(gr_rw)) {
    gr_rw$window_start <- w_start
    gr_rw$window_end   <- w_end
    results_gr_rw[[counter]] <- gr_rw
  }

  # Afișez progresul la fiecare 10 ferestre ca să știu că scriptul nu s-a blocat
  if (counter %% 10 == 0)
    cat("  Fereastra", counter, "/", n_windows, "— capăt:", w_end, "\n")

  counter <- counter + 1
}

rw_pc_df <- do.call(rbind, results_pc_rw)
rw_gr_df <- do.call(rbind, results_gr_rw)

write.csv(rw_pc_df, "outputs/time_windows/rolling_partialcorr_extended.csv", row.names = FALSE)
write.csv(rw_gr_df, "outputs/time_windows/rolling_granger_extended.csv",     row.names = FALSE)
cat("Salvate: rolling_partialcorr_extended.csv + rolling_granger_extended.csv\n")


# =============================================================================
# SECȚIUNEA 8: Grafice de evoluție temporală
#
# Trasez câte un grafic per metrică, cu câte o linie per sector.
# Marchez evenimentele economice majore cu linii verticale punctate ca să pot
# corela vizual schimbările de centralitate cu șocurile de pe piață.
# =============================================================================

cat("\n--- Secțiunea 8: Grafice rolling ---\n")

# Evenimentele pe care vreau să le evidențiez pe toate graficele temporale
events <- list(
  list(date = "2020-03-01", label = "COVID crash"),
  list(date = "2022-02-24", label = "Invazie Ucraina"),
  list(date = "2023-03-15", label = "Criză bancară SUA")
)

plot_rolling_metric <- function(rw_df, metric_col, title, filename) {
  rw_df$date <- as.Date(rw_df$window_end)

  p <- ggplot(rw_df, aes(x = date, y = .data[[metric_col]],
                          color = sector, group = sector)) +
    geom_line(linewidth = 0.75, alpha = 0.85) +
    labs(
      title = title,
      x     = "Capătul ferestrei rolling",
      y     = metric_col,
      color = "Sector"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title      = element_text(face = "bold", hjust = 0.5),
      legend.position = "right"
    )

  # Adaug câte o linie verticală punctată pentru fiecare eveniment major;
  # textul e rotit ca să nu se suprapună cu liniile sectoriale
  for (ev in events) {
    p <- p +
      geom_vline(
        xintercept = as.Date(ev$date),
        linetype   = "dashed",
        color      = "gray40",
        linewidth  = 0.55
      ) +
      annotate(
        "text",
        x      = as.Date(ev$date),
        y      = Inf,
        label  = ev$label,
        angle  = 90, vjust = -0.3, hjust = 1.1,
        size   = 2.8, color = "gray40"
      )
  }

  ggsave(filename, plot = p, width = 10, height = 5, dpi = 180)
  cat("Salvat:", filename, "\n")
}

# Partial-corr — urmăresc în timp cele mai informative metrici
plot_rolling_metric(
  rw_pc_df, "strength",
  "Evoluție strength (partial-corr) — ferestre rolling de 1 an",
  "outputs/rankings/rolling_pc_strength.png"
)
plot_rolling_metric(
  rw_pc_df, "betweenness",
  "Evoluție betweenness (partial-corr) — ferestre rolling de 1 an",
  "outputs/rankings/rolling_pc_betweenness.png"
)
plot_rolling_metric(
  rw_pc_df, "eigenvector",
  "Evoluție eigenvector centrality (partial-corr) — ferestre rolling de 1 an",
  "outputs/rankings/rolling_pc_eigenvector.png"
)
plot_rolling_metric(
  rw_pc_df, "degree",
  "Evoluție degree (partial-corr) — ferestre rolling de 1 an",
  "outputs/rankings/rolling_pc_degree.png"
)

# Granger — mă interesează în special out-degree (cine transmite șocuri)
# și PageRank (cine este "important" în rețea ținând cont de cine îl influențează)
plot_rolling_metric(
  rw_gr_df, "pagerank",
  "Evoluție PageRank (Granger) — ferestre rolling de 1 an",
  "outputs/rankings/rolling_gr_pagerank.png"
)
plot_rolling_metric(
  rw_gr_df, "outdegree",
  "Evoluție out-degree (Granger) — ferestre rolling de 1 an",
  "outputs/rankings/rolling_gr_outdegree.png"
)
plot_rolling_metric(
  rw_gr_df, "indegree",
  "Evoluție in-degree (Granger) — ferestre rolling de 1 an",
  "outputs/rankings/rolling_gr_indegree.png"
)

cat("\n=== DONE 08_sector_rankings.R ===\n")
