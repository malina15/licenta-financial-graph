library(vars)
library(glasso)
library(igraph)
library(xts)

dir.create("outputs/time_windows", showWarnings = FALSE, recursive = TRUE)

# =====================
# Parametri time window
# =====================
window_size <- 252   # ~1 an bursier
step_size   <- 21    # ~1 lună

# =====================
# Încarcă randamentele
# =====================
returns <- readRDS("outputs/returns.rds")

dates <- index(returns)
Y_all <- coredata(returns)
sector_names <- colnames(Y_all)

n <- nrow(Y_all)

results <- list()
counter <- 1

# =====================
# Rolling windows
# =====================
for (start_idx in seq(1, n - window_size, by = step_size)) {

  end_idx <- start_idx + window_size - 1

  Y <- Y_all[start_idx:end_idx, ]
  window_dates <- dates[start_idx:end_idx]

  # VAR(1) - păstrăm lag-ul selectat anterior (SC a dat 1)
  var_fit <- VAR(Y, p = 1, type = "const")

  # Reziduuri + covarianță
  resid_mat <- residuals(var_fit)
  S <- cov(resid_mat)

  # Graphical lasso (păstrăm aceeași penalizare ca în analiza principală)
  rho <- 1.00
  gl <- glasso(S, rho = rho)
  Theta <- gl$wi

  # Partial correlations
  pcor <- -Theta / sqrt(outer(diag(Theta), diag(Theta)))
  diag(pcor) <- 0

  # Adjacency + weights
  adj <- (abs(Theta) > 1e-8) * 1
  diag(adj) <- 0

  W <- pcor
  W[adj == 0] <- 0

  # Graph (undirected)
  g <- graph_from_adjacency_matrix(
    W, mode = "max", weighted = TRUE, diag = FALSE
  )
  V(g)$name <- sector_names

  # Centralitate: strength_abs
  strength_abs <- strength(g, weights = abs(E(g)$weight))

  df <- data.frame(
    window_start = as.character(min(window_dates)),
    window_end   = as.character(max(window_dates)),
    sector       = names(strength_abs),
    strength_abs = as.numeric(strength_abs)
  )

  results[[counter]] <- df
  counter <- counter + 1
}

centrality_time <- do.call(rbind, results)

write.csv(
  centrality_time,
  "outputs/time_windows/centrality_strength_over_time.csv",
  row.names = FALSE
)

cat("DONE TIME WINDOWING\n")
