library(qiimer)
library(dplyr)

#work_dir <- "/home/leej39/treetest"
work_dir <- "YOUR_WORK_DIRECTORY"

#blast_out_fp <- file.path(work_dir, "Streptococcus_dentapri.fasta.blastout")
blast_out_fp <- "YOUR_BLAST_OUT_RESULT_FILE_PATH"

blast_out <- read_blast_table(blast_out_fp)

### filtering control manually until you end up with 30~50 high quality hits
blast_out %<>% filter(alignment_len > 1400 ) %>% filter(pct_identity > 92) %>% filter(gap_openings < 11)
nrow(blast_out)

out_fp <- paste0(blast_out_fp, "_filtered")
write.table(blast_out, file=out_fp, col.names=T, row.names=F, quote=F, sep="\t")

out_fp <- paste0(out_fp, "_accession_only")
write.table(blast_out$subject_id, file=out_fp, col.names=F, row.names=F, quote=F, sep="\t")