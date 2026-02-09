etf_sector_map <- c(
  XLB  = "Materials",
  XLE  = "Energy",
  XLF  = "Financials",
  XLI  = "Industrials",
  XLK  = "Technology",
  XLP  = "Consumer Staples",
  XLU  = "Utilities",
  XLV  = "Health Care",
  XLY  = "Consumer Discretionary",
  XLC  = "Communication Services",
  XLRE = "Real Estate"
)

make_label <- function(etf) {
  sector <- etf_sector_map[[etf]]
  if (is.null(sector) || is.na(sector)) return(etf)
  paste0(etf, " – ", sector)
}
