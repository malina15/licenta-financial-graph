# R/00_download_data.R

library(quantmod)
library(xts)

# ETF-uri pe sectoare (S&P Select Sector SPDR) – recomandat ca proxy pe “sectors”
tickers <- c("XLB","XLE","XLF","XLI","XLK","XLP","XLU","XLV","XLY","XLRE","XLC")

start_date <- as.Date("2016-01-01")
end_date   <- Sys.Date()

get_one <- function(sym) {
  x <- suppressWarnings(getSymbols(sym, src = "yahoo",
                                  from = start_date, to = end_date,
                                  auto.assign = FALSE))
  Ad(x)  # Adjusted close
}

prices_list <- lapply(tickers, get_one)
names(prices_list) <- tickers

# Aliniere pe aceleași zile (intersecție)
prices <- do.call(merge, c(prices_list, all = FALSE))
colnames(prices) <- tickers

# Log-returns zilnice (în %)
returns <- 100 * diff(log(prices))
returns <- na.omit(returns)

dir.create("data", showWarnings = FALSE)
saveRDS(prices,   "data/prices_sectors.rds")
saveRDS(returns,  "data/returns_sectors.rds")

cat("DONE\n")
cat("Rows (days):", nrow(returns), "\n")
cat("Cols (sectors):", ncol(returns), "\n")
cat("From:", as.character(first(index(returns))), "\n")
cat("To:",   as.character(last(index(returns))), "\n")
