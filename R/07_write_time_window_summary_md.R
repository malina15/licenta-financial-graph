df <- read.csv("outputs/time_windows/centrality_strength_over_time.csv", stringsAsFactors = FALSE)

# Top sector per window (max strength_abs)
key <- paste(df$window_start, df$window_end, sep = " | ")
spl <- split(df, key)

top_rows <- do.call(rbind, lapply(spl, function(x) {
  x[which.max(x$strength_abs), c("window_start","window_end","sector","strength_abs")]
}))

top_rows <- top_rows[order(top_rows$window_start), ]

# Scriem raportul Markdown în root (ca să fie versionat pe GitHub)
out_path <- "time_window_summary.md"

lines <- c(
  "# Time windowing summary (rolling windows)",
  "",
  "Acest fișier rezumă analiza de tip rolling window (252 zile, pas 21 zile) pentru rețeaua bazată pe corelații parțiale (VAR residuals + glasso).",
  "",
  "## Top sector (max strength_abs) în fiecare fereastră",
  "",
  "| Window start | Window end | Top sector | Strength_abs |",
  "|---|---|---:|---:|"
)

table_lines <- apply(top_rows, 1, function(r) {
  paste0("| ", r[["window_start"]], " | ", r[["window_end"]], " | ", r[["sector"]], " | ",
         sprintf("%.6f", as.numeric(r[["strength_abs"]])), " |")
})

lines <- c(lines, table_lines, "", "## Note", "",
           "- `strength_abs` măsoară intensitatea totală a legăturilor (ponderi absolute) ale unui sector în rețeaua din fereastra respectivă.",
           "- Schimbările în sectorul dominant între ferestre sugerează o structură dinamică a interdependențelor sectoriale.")

writeLines(lines, out_path)

# Salvăm și CSV-ul (util pentru Word / Excel), într-un folder versionat
dir.create("docs", showWarnings = FALSE)
write.csv(top_rows, "docs/top_sector_per_window.csv", row.names = FALSE)

cat("WROTE time_window_summary.md and docs/top_sector_per_window.csv\n")
