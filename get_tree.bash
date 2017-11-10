#!/bin/bash

if [ $# -ne 1 ]; then
        echo "Usage: $0 path/to/query_fasta [under QIIME2 environment]"
        exit 1
fi

QUERY_FASTA=$1

### Rscript PATH
Rscript_FP="/home/leej39/miniconda3/bin/Rscript"

### SCRIPT TO MAKE A "BLOCKED" FASTA INTO AN "UNBLOCKED" ONE
BLOCK2UNBLOCK_FP="/home/leej39/small_tree/block2unblock.R"

### SCRIPT TO FILTER A BLAST RESULT
FILTER_BLAST_FP="/home/leej39/small_tree/filter_blastout.R"

### SCRIPT TO MAKE A TREE PLOT
MAKE_TREE_PLOT_FP="/home/leej39/small_tree/make_tree_plot.R"

### BLAST PARAMETERS
BLAST_EVALUE=1e-5
BLAST_OUTFMT=7
BLAST_DB="/home/leej39/small_tree/blastdb/LTP"
BLAST_NUM_THREADS=4

### LTP FASTA 
LTP_FASTA="/home/leej39/small_tree/LTP/LTPs128_SSU_unaligned_processed.fasta"

### LTP SPREADSHEET
LTP_SPREADSHEET="/home/leej39/small_tree/LTP/LTPs128_SSU.csv"

###=====================
### MAKE AN "UNBLOCKED" VERSION OF THE QUERY FASTA
###=====================

${Rscript_FP} --vanilla ${BLOCK2UNBLOCK_FP} ${QUERY_FASTA}
UNBLOCKED_QUERY_FASTA="$(dirname ${QUERY_FASTA})/unblocked_$(basename ${QUERY_FASTA})"

###=====================
### BLAST AGAINST THE DATABASE
###=====================

BLAST_OUT_FP="${QUERY_FASTA}.blastout"
blastn -evalue ${BLAST_EVALUE} -outfmt ${BLAST_OUTFMT} -db ${BLAST_DB} -query ${UNBLOCKED_QUERY_FASTA} -num_threads ${BLAST_NUM_THREADS} -out ${BLAST_OUT_FP}

###=====================
### FILTER BLAST RESULT
###=====================

${Rscript_FP} --vanilla ${FILTER_BLAST_FP} ${BLAST_OUT_FP}

###=====================
### MAKE TREE INPUT FASTA
###=====================

ACCESSION="${QUERY_FASTA}.blastout_filtered_accession_only"
TREE_INPUT_FASTA_FP="${QUERY_FASTA}.tree_input"
grep -A 1 --no-group-separator -Fwf ${ACCESSION} ${LTP_FASTA} > ${TREE_INPUT_FASTA_FP}
cat ${UNBLOCKED_QUERY_FASTA} >> ${TREE_INPUT_FASTA_FP}

###=====================
### MAKE TREE INPUT QZA
###=====================

TREE_INPUT_QZA_FP="${QUERY_FASTA}.tree_input.qza"
qiime tools import \
 --input-path ${TREE_INPUT_FASTA_FP} \
 --output-path ${TREE_INPUT_QZA_FP} \
 --type 'FeatureData[Sequence]'

###=====================
### ALIGN TREE INPUT QZA
###=====================

ALIGNED_TREE_INPUT_FP="${QUERY_FASTA}.aligned_tree_input.qza"
qiime alignment mafft \
  --i-sequences ${TREE_INPUT_QZA_FP} \
  --o-alignment ${ALIGNED_TREE_INPUT_FP} 

###=====================
### MASK ALIGN TREE INPUT QZA
###=====================

MASKED_TREE_INPUT_FP="${QUERY_FASTA}.masked_aligned_tree_input.qza"
qiime alignment mask \
  --i-alignment ${ALIGNED_TREE_INPUT_FP} \
  --o-masked-alignment ${MASKED_TREE_INPUT_FP}

###=====================
### MAKE UNROOTED TREE
###=====================

UNROOTED_TREE_FP="${QUERY_FASTA}.unrooted_tree.qza"
qiime phylogeny fasttree \
  --i-alignment ${MASKED_TREE_INPUT_FP} \
  --o-tree ${UNROOTED_TREE_FP}

###=====================
### MAKE ROOTED TREE -- MID-POINT METHOD
###=====================

ROOTED_TREE_FP="${QUERY_FASTA}.rooted_tree.qza"
qiime phylogeny midpoint-root \
  --i-tree ${UNROOTED_TREE_FP} \
  --o-rooted-tree ${ROOTED_TREE_FP}

###=====================
### EXPORT ROOTED TREE AND RENAME
###=====================

qiime tools export ${ROOTED_TREE_FP} --output-dir "$(dirname ${QUERY_FASTA})/rooted_tree"
mv "$(dirname ${QUERY_FASTA})/rooted_tree/tree.nwk" "$(dirname ${QUERY_FASTA})/rooted_tree/$(basename ${QUERY_FASTA}).tree.nwk"

###=====================
### EXPORT MASKED SEQUENCES
###=====================

qiime tools export ${MASKED_TREE_INPUT_FP} --output-dir "$(dirname ${QUERY_FASTA})/masked_sequences"

###=====================
### MAKE TREE PLOT
###=====================

TREE_FP="$(dirname ${QUERY_FASTA})/rooted_tree/$(basename ${QUERY_FASTA}).tree.nwk"
FILTERED_BLASTOUT_FP="${QUERY_FASTA}.blastout_filtered"
MASKED_FASTA_FP="$(dirname ${QUERY_FASTA})/masked_sequences/aligned-dna-sequences.fasta"
${Rscript_FP} --vanilla ${MAKE_TREE_PLOT_FP} ${TREE_FP} ${FILTERED_BLASTOUT_FP} ${MASKED_FASTA_FP} ${LTP_SPREADSHEET} 