library(igraph)

dir.create("outputs", showWarnings = FALSE)

# =========================
# Network 1: Partial corr (glasso) - undirected, weighted
# =========================
edges_pc <- read.csv("outputs/edges.csv", stringsAsFactors = FALSE)

g_pc <- graph_from_data_frame(edges_pc, directed = FALSE)
E(g_pc)$weight <- edges_pc$weight

deg_pc <- degree(g_pc)
str_pc <- strength(g_pc, weights = abs(E(g_pc)$weight))

# pentru betweenness/closeness folosim "distanțe" = 1/|w|
w_pc <- abs(E(g_pc)$weight)
dist_pc <- 1 / (w_pc + 1e-8)

bet_pc <- betweenness(g_pc, directed = FALSE, weights = dist_pc)
clo_pc <- closeness(g_pc, normalized = TRUE, weights = dist_pc)

eig_pc <- eigen_centrality(g_pc, directed = FALSE, weights = abs(E(g_pc)$weight))$vector

cent_pc <- data.frame(
  network = "partial_corr_glasso",
  node = V(g_pc)$name,
  degree = as.numeric(deg_pc),
  strength_abs = as.numeric(str_pc),
  betweenness = as.numeric(bet_pc),
  closeness = as.numeric(clo_pc),
  eigenvector = as.numeric(eig_pc)
)

write.csv(cent_pc, "outputs/centrality_partialcorr.csv", row.names = FALSE)

top3_pc <- head(cent_pc[order(-cent_pc$strength_abs), ], 3)
write.csv(top3_pc, "outputs/top3_partialcorr.csv", row.names = FALSE)

# =========================
# Network 2: Granger - directed, weighted
# =========================
edges_gr <- read.csv("outputs/granger_edges.csv", stringsAsFactors = FALSE)

g_gr <- graph_from_data_frame(edges_gr, directed = TRUE, vertices = unique(c(edges_gr$from, edges_gr$to)))
E(g_gr)$weight <- edges_gr$weight

indeg <- degree(g_gr, mode = "in")
outdeg <- degree(g_gr, mode = "out")
bet_gr <- betweenness(g_gr, directed = TRUE)

# PageRank cu ponderi = -log10(p)
pr_gr <- page_rank(g_gr, directed = TRUE, weights = E(g_gr)$weight)$vector

cent_gr <- data.frame(
  network = "granger",
  node = V(g_gr)$name,
  indegree = as.numeric(indeg),
  outdegree = as.numeric(outdeg),
  betweenness = as.numeric(bet_gr),
  pagerank = as.numeric(pr_gr)
)

write.csv(cent_gr, "outputs/centrality_granger.csv", row.names = FALSE)

top3_gr <- head(cent_gr[order(-cent_gr$pagerank), ], 3)
write.csv(top3_gr, "outputs/top3_granger.csv", row.names = FALSE)

cat("DONE CENTRALITY\n")
