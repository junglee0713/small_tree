library(ggplot2)
library(ggtree)
library(dplyr)
library(reshape2)

tree_fp <- "/Users/leej39/Dropbox/0_CHOP/make_tree/Strep.nwk"
ltp_path <- "/Users/leej39/Dropbox/0_CHOP/make_tree/LTPs128_SSU.csv"

kk <- read.tree(tree_fp)

ltp <- read.table(file=ltp_path, header=F, sep="\t", as.is=T)[ ,c(1,5)]
ltp <- ltp[ltp$V1 %in% kk$tip.label, ]

tip.label.conv <- kk$tip.label %>% melt() %>% merge(ltp, by.x="value", by.y="V1", all.x=T)
names(tip.label.conv) <- c("accession.num", "organism.name")
tip.label.conv$organism.name[tip.label.conv$accession.num=="AB469560.1"] <- "Streptococcus dentapri"

kk$tip.label <- tip.label.conv$organism.name[match(kk$tip.label, tip.label.conv$accession.num)]
kk$tip.label <- gsub("Streptococcus", "S.", kk$tip.label)

kk$color <- rep("black", length(kk$tip.label))
kk$color[kk$tip.label=="S. dentapri"] <- "red"

treeplot <- ggplot(kk, aes()) + geom_tree() + theme_tree() + xlab("") + 
  ylab("") + geom_tiplab() + theme_tree2() + ggplot2::xlim(0, 0.1)
treeplot
ggsave("/Users/leej39/Dropbox/0_CHOP/make_tree/Streptococcus_dentapri_tree_unknown.pdf")
