library(vars)
library(glasso)
library(xts)

# Crearea directoarelor pentru rezultate și log-uri
dir.create("outputs", showWarnings = FALSE)
dir.create("logs", showWarnings = FALSE)

# Redirecționarea output-ului către un fișier de log (și afișare simultană în consolă)
log_file <- sprintf("logs/03_glasso_selection_%s.txt", format(Sys.time(), "%Y%m%d_%H%M%S"))
sink(log_file, split = TRUE)

# Încărcarea randamentelor zilnice preprocesate
returns <- readRDS("data/returns_sectors.rds")
Y <- as.matrix(returns)

# Selectarea ordinului VAR conform criteriului Schwarz și estimarea modelului
sel <- VARselect(Y, lag.max = 10, type = "const")
p <- sel$selection[["SC(n)"]]
var_fit <- VAR(Y, p = p, type = "const")

# Calculul matricei de covarianță a reziduurilor (inovațiilor) din VAR
resid_mat <- residuals(var_fit)
S <- cov(resid_mat)

# Estimarea graphical lasso pe o grilă de valori ale penalizării rho
rho_grid <- seq(0.05, 1.00, by = 0.05)
gl_list <- lapply(rho_grid, function(rho) glasso(S, rho = rho))

# Determinarea muchiilor prin prag pe elementele off-diagonale ale matricei de precizie
eps <- 1e-4
edge_density <- sapply(gl_list, function(g) {
  Theta <- g$wi
  n <- ncol(Theta)
  A <- (abs(Theta) > eps) * 1
  diag(A) <- 0
  m <- sum(A) / 2
  m / (n * (n - 1) / 2)
})

# Calculul criteriului BIC pentru selecția parametrului rho
bic_vals <- sapply(gl_list, function(g) {
  Theta <- g$wi
  n <- nrow(S)
  logdet <- as.numeric(determinant(Theta, logarithm = TRUE)$modulus)
  tr_term <- sum(S * Theta)
  loglik <- (logdet - tr_term)
  edges <- sum(abs(Theta[upper.tri(Theta)]) > eps)
  k <- edges
  -2 * loglik + log(nrow(Y)) * k
})



# Salvarea densității rețelei în funcție de rho
dens_df <- data.frame(rho = rho_grid, density = edge_density, bic = bic_vals)
write.csv(dens_df, "outputs/glasso_density_grid.csv", row.names = FALSE)

# Reprezentarea relației rho–densitate
png("outputs/glasso_density_curve.png", width = 1400, height = 900)
plot(dens_df$rho, dens_df$density, type = "b", xlab = "rho", ylab = "Densitate retea")
dev.off()

cat("DONE\n")
sink()
