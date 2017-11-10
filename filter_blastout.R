library(qiimer, lib.loc="/home/leej39/miniconda3/lib/R/library")
library(magrittr, lib.loc="/home/leej39/miniconda3/lib/R/library")
suppressMessages(library(dplyr, lib.loc="/home/leej39/miniconda3/lib/R/library"))

args <- commandArgs(trailingOnly = TRUE)
blast_out_fp <- args[1] 

blast_out <- read_blast_table(blast_out_fp)

# HOW TO AUTOMATE THE FILTERING?? CURRENTLY USING TOP 30 BIT_SCORES AND A REMOTE ONE
upto <- min(nrow(blast_out)-1, 30)
extra <- min(nrow(blast_out), 50)

blast_out %<>% arrange(desc(bit_score)) %>% slice(c(1:upto, extra))

out_fp <- paste0(blast_out_fp, "_filtered")
write.table(blast_out, file=out_fp, col.names=T, row.names=F, quote=F, sep="\t")

out_fp <- paste0(out_fp, "_accession_only")
write.table(blast_out$subject_id, file=out_fp, col.names=F, row.names=F, quote=F, sep="\t")
