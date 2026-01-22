library(vars)
library(glasso)
library(igraph)

# Încărcarea seriilor de randamente calculate anterior
returns <- readRDS("data/returns_sectors.rds")

cat("Returns loaded.\n")
cat("Rows (days):", nrow(returns), "\n")
cat("Cols (sectors):", ncol(returns), "\n")
cat("From:", as.character(first(index(returns))), "\n")
cat("To:",   as.character(last(index(returns))), "\n\n")

# Conversia obiectului xts într-o matrice numerică
Y <- as.matrix(returns)

# Selectarea ordinului optim de întârziere pentru modelul VAR
maxlags <- 10
sel <- VARselect(Y, lag.max = maxlags, type = "const")
cat("Lag selection criteria:\n")
print(sel$criteria)
cat("\nSelected lags:\n")
print(sel$selection)
cat("\n")

# Ordinul ales conform criteriului Schwarz
p <- sel$selection[["SC(n)"]]
cat("Chosen lag p (SC):", p, "\n\n")

# Estimarea modelului VAR cu intercept
var_fit <- VAR(Y, p = p, type = "const")
cat("VAR estimated.\n\n")

# Calculul matricei de covarianță a reziduurilor VAR
resid_mat <- residuals(var_fit)
S <- cov(resid_mat)
cat("Residual covariance matrix S computed. Dim:", paste(dim(S), collapse="x"), "\n\n")

# Estimarea matricei de precizie folosind graphical lasso pentru mai multe valori ale penalizării
rho_grid <- c(0.05, 0.1, 0.15, 0.2, 0.3)

gl_list <- lapply(rho_grid, function(rho) glasso(S, rho = rho))
names(gl_list) <- paste0("rho_", rho_grid)

# Calculul densității rețelei asociate fiecărei valori rho
edge_density <- sapply(gl_list, function(g) {
  Theta <- g$wi
  A <- (abs(Theta) > 1e-8) * 1
  diag(A) <- 0
  m <- sum(A) / 2
  n <- ncol(Theta)
  m / (n * (n - 1) / 2)
})

dens_df <- data.frame(rho = rho_grid, density = edge_density)
print(dens_df)
cat("\n")

# Matricea de precizie estimată pentru valoarea selectată a penalizării
rho <- 0.15
gl <- glasso(S, rho = rho)
Theta <- gl$wi

cat("Chosen rho:", rho, "\n")
cat("Theta (precision) dim:", paste(dim(Theta), collapse="x"), "\n\n")

# Calculul corelațiilor parțiale pe baza matricei de precizie
pcor <- -Theta / sqrt(outer(diag(Theta), diag(Theta)))
diag(pcor) <- 0

# Construirea matricei de adiacență pe baza elementelor nenule din matricea de precizie
adj <- (abs(Theta) > 1e-8) * 1
diag(adj) <- 0

# Ponderarea muchiilor cu valorile corelațiilor parțiale
W <- pcor
W[adj == 0] <- 0

# Construirea rețelei neorientate folosind pachetul igraph
g <- graph_from_adjacency_matrix(W, mode = "undirected", weighted = TRUE, diag = FALSE)
V(g)$name <- colnames(Y)

cat("Graph built.\n")
cat("Nodes:", vcount(g), "\n")
cat("Edges:", ecount(g), "\n\n")

# Salvarea rezultatelor numerice
dir.create("outputs", showWarnings = FALSE)

write.csv(S,     "outputs/var_residual_cov_S.csv", row.names = TRUE)
write.csv(Theta, "outputs/glasso_precision_Theta.csv", row.names = TRUE)
write.csv(pcor,  "outputs/partial_correlations.csv", row.names = TRUE)

# Calculul unor măsuri simple de centralitate în rețea
deg <- degree(g)
str_abs <- strength(g, weights = abs(E(g)$weight))

centrality_df <- data.frame(
  sector = V(g)$name,
  degree = deg,
  strength_abs = str_abs
)
centrality_df <- centrality_df[order(-centrality_df$strength_abs), ]
write.csv(centrality_df, "outputs/centrality.csv", row.names = FALSE)

# Reprezentarea grafică a rețelei
png("outputs/network.png", width = 1400, height = 900)
plot(
  g,
  vertex.size = 32,
  vertex.label.cex = 1.1,
  edge.width = 2 + 8 * abs(E(g)$weight),
  main = paste("VAR residuals + glasso network (rho =", rho, ")")
)
dev.off()

cat("DONE\n")
