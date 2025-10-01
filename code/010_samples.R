#!/usr/bin/env Rscript
rm(list = ls(all.names = TRUE))
set.seed(20)

options(
    rlang_backtrace_on_error = "full",
    error = rlang::entrace,
    menu.graphics = FALSE,
    repos = c("CRAN" = "https://mirror.las.iastate.edu/CRAN"),
)


#######################################################################
# Load R packages
#######################################################################


library(tidyverse)
library(glue)
library(openxlsx)



#######################################################################
# Script parameters
#######################################################################



proj <- "PROJNAME"
prefix <- "010_"
out <- glue("{prefix}SCRIPTNAME")
group <- "GROUP"
proj_dir <- glue("/home/{group}/shared/ris/knut0297/{proj}")
out_dir <- glue("{proj_dir}/code_out/{out}")




if (!dir.exists(glue("{out_dir}"))) {
    dir.create(glue("{out_dir}"), recursive = TRUE)
}
setwd(glue("{out_dir}"))








#######################################################################
# Session info
#######################################################################

writeLines(capture.output(sessionInfo()), paste0("sessionInfo_", format(Sys.time(), "%Y%m%d-%H%M%S"), ".txt"))

