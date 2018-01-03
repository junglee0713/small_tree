#!/bin/bash

if [ $# -ne 1 ]; then
        echo "Usage: $0 absolute/path/to/query_fasta"
        exit 1
fi

QUERY_FASTA=$1
QUERY_DIR=$(dirname ${QUERY_FASTA})
QUERY_BASENAME=$(basename ${QUERY_FASTA})

### SCRIPT TO FILTER A BLAST RESULT
FILTER_BLAST_FP="./filter_blastout.R"

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
### MAKE AN "UNBLOCKED" VERSION OF THE QUERY FASTA
###=====================

UNBLOCKED_QUERY_FASTA="${QUERY_DIR}/unblocked_${QUERY_BASENAME}"
cat ${QUERY_FASTA} | awk '/^>/ {printf("%s\n",">Query");next} {printf("%s",$0)} END {printf("\n")}' > ${UNBLOCKED_QUERY_FASTA}

###=====================
### BLAST AGAINST THE DATABASE
###=====================

BLAST_OUT_FP="${QUERY_FASTA}.blastout"
blastn -evalue ${BLAST_EVALUE} -outfmt ${BLAST_OUTFMT} -db ${BLAST_DB} -query ${UNBLOCKED_QUERY_FASTA} -num_threads ${BLAST_NUM_THREADS} -out ${BLAST_OUT_FP}

###=====================
### FILTER BLAST RESULT
###=====================

Rscript --vanilla ${FILTER_BLAST_FP} ${BLAST_OUT_FP}
rm -f ${BLAST_OUT_FP}

###=====================
### MAKE TREE INPUT FASTA
###=====================

ACCESSION="${QUERY_FASTA}.blastout_filtered_accession_only"
UNALIGNED_TREE_INPUT_FASTA_FP="${QUERY_FASTA}_unaligned.tree_input"
grep -A 1 --no-group-separator -Fwf ${ACCESSION} ${LTP_FASTA} > ${UNALIGNED_TREE_INPUT_FASTA_FP}

###=====================
### ALIGN TREE INPUT
###=====================

ALIGNED_TREE_INPUT_FASTA_FP="${QUERY_FASTA}_aligned.tree_input"
muscle -in ${UNALIGNED_TREE_INPUT_FASTA_FP} -out ${ALIGNED_TREE_INPUT_FASTA_FP}
rm -f ${UNALIGNED_TREE_INPUT_FASTA_FP}

###=====================
### MAKE AN "UNBLOCKED" ALIGNED TREE INPUT
###=====================

UNBLOCKED_ALIGNED_TREE_INPUT="${QUERY_FASTA}_unblocked_aligned.tree_input"
cat ${ALIGNED_TREE_INPUT_FASTA_FP} | awk '/^>/ {printf("\n%s\n",$1);next} {printf("%s",$0)} END {printf("\n")}' | awk 'NR>1 {print}' > ${UNBLOCKED_ALIGNED_TREE_INPUT}
rm -f ${ALIGNED_TREE_INPUT_FASTA_FP}

###=====================
### MAKE TREE USING REFERENCE SEQUENCES ONLY
###=====================

raxmlHPC -m GTRGAMMA -p 12345 -s ${UNBLOCKED_ALIGNED_TREE_INPUT} -w ${QUERY_DIR} -n RefTree

###=====================
### INSERT QUERY SEQEUNCE INTO THE ALIGNED REFERENCE SEQUENCES MAKE 
###=====================

COMBINED_ALIGNED="${QUERY_FASTA}_combined_aligned"
muscle -profile -in1 ${UNBLOCKED_ALIGNED_TREE_INPUT} -in2 ${UNBLOCKED_QUERY_FASTA} -out ${COMBINED_ALIGNED}
rm -f ${UNBLOCKED_QUERY_FASTA}
rm -f ${UNBLOCKED_ALIGNED_TREE_INPUT}

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

UNBLOCKED_COMBINED_ALIGNED="${QUERY_FASTA}_unblocked_combined_aligned"
cat ${COMBINED_ALIGNED} | awk '/^>/ {printf("\n%s\n",$1);next} {printf("%s",$0)} END {printf("\n")}' | awk 'NR>1 {print}' > ${UNBLOCKED_COMBINED_ALIGNED}
rm -f ${COMBINED_ALIGNED}

###=====================
### MAKE TREE PLOT
###=====================

FILTERED_BLASTOUT_FP="${QUERY_FASTA}.blastout_filtered"
Rscript --vanilla ${MAKE_TREE_PLOT_FP} ${TREE_FP} ${FILTERED_BLASTOUT_FP} ${UNBLOCKED_COMBINED_ALIGNED} ${LTP_SPREADSHEET} 
rm -f ${FILTERED_BLASTOUT_FP}
rm -f "${FILTERED_BLASTOUT_FP}_accession_only"
rm -f ${UNBLOCKED_COMBINED_ALIGNED}
