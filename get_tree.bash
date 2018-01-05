#!/bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
        echo "Usage: $0 absolute/path/to/query_fasta"
        exit 1
fi

QUERY_FASTA=$1
QUERY_DIR=$(dirname ${QUERY_FASTA})
QUERY_BASENAME=$(basename ${QUERY_FASTA})

### SCRIPT TO FILTER A BLAST RESULT
FILTER_BLAST_FP="./filter_blastout.R"

### SCRIPT TO FILTER LTP FASTA
FILTER_FP="./filter_fasta.py"

### SCRIPT TO NORMALIZE A FASTA FILE
NORMALIZE_FP="./normalize_fasta.py"

### SCRIPT TO MAKE A TREE PLOT
MAKE_TREE_PLOT_FP="./make_tree_plot.R"

### BLAST PARAMETERS
BLAST_EVALUE=1e-5
BLAST_OUTFMT=7
BLAST_DB="./blastdb/LTP"
BLAST_NUM_THREADS=4

### LTP FASTA 
LTP_FASTA="./LTP/LTPs128_SSU_unaligned_processed.fasta"

### LTP SPREADSHEET
LTP_SPREADSHEET="./LTP/LTPs128_SSU.csv"

###=====================
### AVOID DUPLICATED ACCESSION BY CHANGING QUERY HEADER
###=====================

QUERY_FASTA_NEW="${QUERY_FASTA}.new"
awk '{gsub(">", ">Query ", $1); print}' ${QUERY_FASTA} > ${QUERY_FASTA_NEW}

###=====================
### BLAST AGAINST THE DATABASE
###=====================

BLAST_OUT_FP="${QUERY_FASTA}.blastout"
blastn -evalue ${BLAST_EVALUE} -outfmt ${BLAST_OUTFMT} -db ${BLAST_DB} -query ${QUERY_FASTA_NEW} -num_threads ${BLAST_NUM_THREADS} -out ${BLAST_OUT_FP}

###=====================
### FILTER BLAST RESULT
###=====================

Rscript --vanilla ${FILTER_BLAST_FP} ${BLAST_OUT_FP}
rm -f ${BLAST_OUT_FP}

###=====================
### FILTER LTP FASTA
###=====================

ACCESSION="${QUERY_FASTA}.blastout_filtered_accession_only"
FILTERED_LTP_FASTA="${QUERY_FASTA}_filtered_LTP.fasta"

python ${FILTER_FP} ${ACCESSION} ${LTP_FASTA} ${FILTERED_LTP_FASTA}
rm -f ${ACCESSION}

###=====================
### ALIGN FILTERED LTP FASTA
###=====================

ALIGNED_LTP_FASTA="${QUERY_FASTA}_aligned_filtered_LTP.fasta"
muscle -in ${FILTERED_LTP_FASTA} -out ${ALIGNED_LTP_FASTA}
rm -f ${FILTERED_LTP_FASTA}

###=====================
### MAKE TREE USING REFERENCE SEQUENCES ONLY
###=====================

raxmlHPC -m GTRGAMMA -p 12345 -s ${ALIGNED_LTP_FASTA} -w ${QUERY_DIR} -n RefTree

###=====================
### INSERT QUERY SEQEUNCE INTO THE ALIGNED REFERENCE SEQUENCES MAKE 
###=====================

COMBINED_ALIGNED="${QUERY_FASTA}_combined_aligned"
muscle -profile -in1 ${ALIGNED_LTP_FASTA} -in2 ${QUERY_FASTA_NEW} -out ${COMBINED_ALIGNED}
rm -f ${ALIGNED_LTP_FASTA}
rm -f ${QUERY_FASTA_NEW} 

###=====================
### INSERT QUERY SEQEUNCE INTO THE EXISTING TREE  
###=====================

raxmlHPC -f v -s ${COMBINED_ALIGNED} -t ${QUERY_DIR}/RAxML_bestTree.RefTree -w ${QUERY_DIR} -m GTRGAMMA -n CombinedTree
TREE_FP="${QUERY_DIR}/${QUERY_BASENAME}.tree.nwk"
mv "${QUERY_DIR}/RAxML_labelledTree.CombinedTree" ${TREE_FP}
rm -f ${QUERY_DIR}/RAxML_*
rm -f "${COMBINED_ALIGNED}.reduced"

###=====================
### MAKE UNBLOCKED COMBINED ALIGNED -- FOR DNA PLOT
###=====================

NORMALIZED_COMBINED_ALIGNED="${QUERY_FASTA}_normalized"
python ${NORMALIZE_FP} ${COMBINED_ALIGNED} ${NORMALIZED_COMBINED_ALIGNED}
rm -f ${COMBINED_ALIGNED}

###=====================
### MAKE TREE PLOT
###=====================

FILTERED_BLASTOUT_FP="${QUERY_FASTA}.blastout_filtered"
Rscript --vanilla ${MAKE_TREE_PLOT_FP} ${TREE_FP} ${FILTERED_BLASTOUT_FP} ${NORMALIZED_COMBINED_ALIGNED} ${LTP_SPREADSHEET} 
rm -f ${FILTERED_BLASTOUT_FP}
rm -f ${NORMALIZED_COMBINED_ALIGNED}
rm -f ${TREE_FP}
