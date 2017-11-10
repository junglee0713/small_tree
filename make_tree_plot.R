library(ggplot2, lib.loc="/home/leej39/miniconda3/lib/R/library")
suppressMessages(library(ggtree, lib.loc="/home/leej39/miniconda3/lib/R/library"))
suppressMessages(library(dplyr, lib.loc="/home/leej39/miniconda3/lib/R/library"))
library(reshape2, lib.loc="/home/leej39/miniconda3/lib/R/library")
library(dnaplotr, lib.loc="/home/leej39/miniconda3/lib/R/library") ### from Scott Sherrill-Mix

args <- commandArgs(trailingOnly = TRUE)

### INPUT FILE PATHS

tree_fp <- args[1]
filtered_blast_fp <- args[2]
masked_fasta_fp <- args[3]
ltp_fp <- args[4]

### OUTPUT FILE PATHS
plotDNA_out_fp <- gsub(".tree.nwk$", ".plotDNA.pdf", tree_fp)
output_fp <- gsub(".tree.nwk$", ".tree.pdf", tree_fp)

### READ IN TREE
tree <- read.tree(tree_fp)

### READ IN FILTERED BLAST OUT 
fb <- read.table(file=filtered_blast_fp, header=T, sep="\t", as.is=T)
query_id <- unique(fb$query_id)
control_id <- fb[order(fb$bit_score),"subject_id"][1] 

### READ IN LTP
ltp <- read.table(file=ltp_fp, header=F, sep="\t", as.is=T)[ ,c(1,5)] %>%
  rename(accession=V1, organism=V5)

### CREATE A DATA FRAME TO MODIFY TIP.LABELS
df <- data.frame(line=1:length(tree$tip.label), tip.label=tree$tip.label) %>%
  merge(ltp, by.x="tip.label", by.y="accession", all.x=T) %>%
  arrange(line)
df$organism[df$tip.label==query_id] <- query_id
df$type <- "similar"
df$type[df$tip.label==query_id] <- "query"
df$type[df$tip.label==control_id] <- "control"

treeplot <- ggplot(tree)
max_x_pos <- max(treeplot$data$x)
 
treeplot <- treeplot %<+% df + geom_tree() + theme_tree() + xlab("") + 
  ylab("") + geom_tiplab(aes(label=organism,color=type)) + theme_tree2() + ggplot2::xlim(0, 2*max_x_pos)
ggsave(filename=output_fp, plot=treeplot)

### plotDNA
seqsOrig <- read.table(file=masked_fasta_fp, header=F, as.is=T, fill=T)$V1
seq_name_pos <- grep("^>", seqsOrig)
seq_accession <- gsub(">", "", seqsOrig[seq_name_pos])
seqs <- seqsOrig[seq_name_pos+1]
names(seqs) <- seq_accession

### merge sequence and df
m <- seqs %>% 
  melt() %>%
  merge(df, by.x="row.names", by.y="tip.label")
  
groupOrder <- c("query", "similar", "control")

pdf(file=plotDNA_out_fp)
  par(mar=c(6.5, 5, 5, 5))
  plotDNA(seqs, groups=factor(m$type, levels=groupOrder))
dev.off()

