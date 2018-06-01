if (!require("rmarkdown")) {
    install.packages("rmarkdown",repos = "https://cloud.r-project.org")
  }
  if (packageVersion("rmarkdown") < "1.3") {
    install.packages("rmarkdown", repos = "https://cloud.r-project.org")
  }
  print("Generating reports (HTML, PDF & WORD")
  rmarkdown::render(
    input = "input/report.Rmd",
    output_format = paste0(c("html", "pdf", "word"), "_document"),
    output_dir = "output"
  )
