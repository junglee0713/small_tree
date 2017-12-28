#!/bin/bash

if [ $# -ne 1 ]; then
        echo "Usage: $0 path/to/query_fasta"
        exit 1
fi

QUERY_FASTA=$1
QUERY_DIR=$(dirname ${QUERY_FASTA})
QUERY_BASENAME=$(basename ${QUERY_FASTA})

### Rscript PATH
Rscript_FP="${HOME}/miniconda3/bin/Rscript"

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

### SCRIPT TO TRIM UNINFORMATIVE COLUMNS FROM ALIGNED SEQUENCES
TRIM_FP="/home/leej39/miniconda3/bin/o-trim-uninformative-columns-from-alignment"

### RAxML SCRIPT
RAxML="/home/leej39/standard-RAxML-8.2.11/raxmlHPC-PTHREADS-AVX"

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

${Rscript_FP} --vanilla ${FILTER_BLAST_FP} ${BLAST_OUT_FP}
rm -f ${BLAST_OUT_FP}

###=====================
### MAKE TREE INPUT FASTA
###=====================

ACCESSION="${QUERY_FASTA}.blastout_filtered_accession_only"
UNALIGNED_TREE_INPUT_FASTA_FP="${QUERY_FASTA}_unaligned.tree_input"
grep -A 1 --no-group-separator -Fwf ${ACCESSION} ${LTP_FASTA} > ${UNALIGNED_TREE_INPUT_FASTA_FP}
cat ${UNBLOCKED_QUERY_FASTA} >> ${UNALIGNED_TREE_INPUT_FASTA_FP}
rm -f ${UNBLOCKED_QUERY_FASTA}

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
### TRIM UNINFORMATIVE COLUMNS FROM MASK ALIGNMENT
###=====================

TRIMMED_TREE_INPUT="${QUERY_FASTA}_unblocked_aligned.tree_input-TRIMMED"
${TRIM_FP} ${UNBLOCKED_ALIGNED_TREE_INPUT}
rm -f ${UNBLOCKED_ALIGNED_TREE_INPUT}

###=====================
### MAKE TREE
###=====================

${RAxML} -m GTRCAT -p 12345 -s ${TRIMMED_TREE_INPUT} -w ${QUERY_DIR} -n ${QUERY_BASENAME}
TREE_FP="${QUERY_DIR}/${QUERY_BASENAME}.tree.nwk"
mv "${QUERY_DIR}/RAxML_bestTree.${QUERY_BASENAME}" ${TREE_FP}
rm -f ${QUERY_DIR}/RAxML_*
rm -f "${TRIMMED_TREE_INPUT}.reduced"

###=====================
### MAKE TREE PLOT
###=====================

FILTERED_BLASTOUT_FP="${QUERY_FASTA}.blastout_filtered"
${Rscript_FP} --vanilla ${MAKE_TREE_PLOT_FP} ${TREE_FP} ${FILTERED_BLASTOUT_FP} ${TRIMMED_TREE_INPUT} ${LTP_SPREADSHEET} 
rm -f ${FILTERED_BLASTOUT_FP}
rm -f "${FILTERED_BLASTOUT_FP}_accession_only"
rm -f ${TRIMMED_TREE_INPUT}
