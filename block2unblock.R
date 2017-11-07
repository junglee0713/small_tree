args <- commandArgs(trailingOnly = TRUE)

block_file_fp <- args[1] #block_file_fp <- "/home/leej39/tree_software/data/Blautia_caecimuris.fasta"

block <- read.table(file=block_file_fp, header=F, as.is=T, fill=T)$V1

seq_name_pos <- grep("^>", block)
seq_names <- block[seq_name_pos]
seq_start <- seq_name_pos + 1
seq_end <- c(seq_name_pos[-1] - 1, length(block)) 
seq_comb <- NULL

for (i in 1:length(seq_name_pos)) {
  seq_comb[i] <- paste(block[seq_start[i]:seq_end[i]], collapse="")
}

df <- c(rbind(seq_names, seq_comb))

# out file path
tmp <- unlist(strsplit(block_file_fp, "/"))
tmp[length(tmp)] <- paste0("unblocked_", tmp[length(tmp)])

unblock_file_fp <- paste(tmp, collapse="/") 
write.table(df, file=unblock_file_fp, sep="\n", col.names=F, row.names=F, quote=F)
