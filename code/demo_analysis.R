#!/usr/bin/env Rscript

# Setup paths
script_dir <- dirname(normalizePath(sys.frame(1)$ofile, mustWork = FALSE))
proj_dir <- dirname(script_dir)
out_dir <- file.path(proj_dir, "code_out", "demo_analysis")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
setwd(out_dir)

# Load packages
library(tidyverse)

# Generate sample data
set.seed(42)
sample_data <- tibble(
    sample_id = paste0("Sample_", 1:20),
    condition = rep(c("Control", "Treatment"), each = 10),
    expression = c(rnorm(10, mean = 5, sd = 1.5), 
                   rnorm(10, mean = 8, sd = 1.5))
)

# Save data
write_csv(sample_data, "sample_data.csv")

# Create and save plot
p <- ggplot(sample_data, aes(x = condition, y = expression, fill = condition)) +
    geom_boxplot() +
    geom_jitter(width = 0.2, alpha = 0.5) +
    theme_minimal() +
    labs(title = "Gene Expression: Control vs Treatment",
         x = "Condition", y = "Expression Level") +
    scale_fill_brewer(palette = "Set2")

ggsave("expression_boxplot.png", p, width = 8, height = 6, dpi = 300)

cat("Done! Results in:", out_dir, "\n")
