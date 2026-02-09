library(vars)
library(igraph)
library(car)

dir.create("outputs", showWarnings = FALSE)

# Încarcă artefactele generate de 01
returns <- readRDS("outputs/returns.rds")
var_fit <- readRDS("outputs/var_fit.rds")

# Lucrăm cu numele variabilelor (sectoare)
vars_names <- colnames(returns)
p <- var_fit$p

alpha <- 0.05

make_hypotheses <- function(cause, p) {
  paste0(cause, ".l", 1:p, " = 0")
}

edge_rows <- list()

# Testăm: cause -> effect (pe ecuația lui effect)
for (effect in vars_names) {
  eq <- var_fit$varresult[[effect]]

  for (cause in vars_names) {
    if (cause == effect) next

    hyps <- make_hypotheses(cause, p)

    test <- tryCatch(
      car::linearHypothesis(eq, hyps),
      error = function(e) NULL
    )
    if (is.null(test)) next

    pval <- test$`Pr(>F)`[2]
    if (is.na(pval)) next

    if (pval < alpha) {
      edge_rows[[length(edge_rows) + 1]] <- data.frame(
        from = cause,
        to = effect,
        p_value = pval,
        weight = -log10(pval)
      )
    }
  }
}

edges_df <- if (length(edge_rows) == 0) {
  data.frame(from=character(), to=character(), p_value=numeric(), weight=numeric())
} else {
  do.call(rbind, edge_rows)
}

write.csv(edges_df, "outputs/granger_edges.csv", row.names = FALSE)

g <- igraph::graph_from_data_frame(edges_df, directed = TRUE, vertices = vars_names)
if (nrow(edges_df) > 0) E(g)$weight <- edges_df$weight

png("outputs/granger_network.png", width = 1400, height = 900)
plot(
  g,
  edge.arrow.size = 0.4,
  vertex.size = 32,
  vertex.label.cex = 1.1,
  main = paste0("Granger network (alpha=", alpha, ", p=", p, ")")
)
dev.off()

cat("DONE GRANGER\n")
