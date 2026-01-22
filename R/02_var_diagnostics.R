library(vars)
library(xts)

dir.create("outputs", showWarnings = FALSE)
dir.create("logs", showWarnings = FALSE)

log_file <- sprintf("logs/02_var_diagnostics_%s.txt", format(Sys.time(), "%Y%m%d_%H%M%S"))
sink(log_file, split = TRUE)

cat("VAR diagnostics\n")
cat("Run timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n\n")

returns <- readRDS("data/returns_sectors.rds")
Y <- as.matrix(returns)

cat("Data summary\n")
cat("Rows (days):", nrow(Y), "\n")
cat("Cols (sectors):", ncol(Y), "\n")
cat("From:", as.character(first(index(returns))), "\n")
cat("To:",   as.character(last(index(returns))), "\n\n")

maxlags <- 10
sel <- VARselect(Y, lag.max = maxlags, type = "const")

cat("Lag selection criteria\n")
print(sel$criteria)
cat("\nLag selection (recommended)\n")
print(sel$selection)
cat("\n")

p <- sel$selection[["SC(n)"]]
cat("Chosen lag p (SC):", p, "\n\n")

var_fit <- VAR(Y, p = p, type = "const")

cat("VAR summary\n")
print(summary(var_fit))
cat("\n")

# Stabilitate (CUSUM)
stability_obj <- stability(var_fit, type = "OLS-CUSUM")
png("outputs/var_stability_cusum.png", width = 1400, height = 900)
plot(stability_obj)
dev.off()
cat("Saved: outputs/var_stability_cusum.png\n")

# Autocorelație reziduuri (Portmanteau)
cat("\nResidual serial correlation test (Portmanteau)\n")
serial_res <- serial.test(var_fit, lags.pt = 12, type = "PT.asymptotic")
print(serial_res)

# Heteroscedasticitate de tip ARCH
cat("\nARCH effects test\n")
arch_res <- arch.test(var_fit, lags.multi = 12)
print(arch_res)

# Normalitate (Jarque-Bera multivariat)
cat("\nNormality test\n")
norm_res <- normality.test(var_fit)
print(norm_res)

# Salvare rezultate esențiale pentru raport (text)
saveRDS(list(
  lag_selection = sel,
  chosen_p = p,
  serial_test = serial_res,
  arch_test = arch_res,
  normality_test = norm_res
), file = "outputs/var_diagnostics_results.rds")

cat("\nSaved: outputs/var_diagnostics_results.rds\n")
cat("\nDONE\n")

sink()
