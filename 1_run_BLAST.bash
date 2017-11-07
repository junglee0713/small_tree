#!/bin/bash

if [ $# -ne 1 ]; then
        echo "Usage: $0 QUERY_FASTA"
        exit 1
fi

QUERY_FASTA=$1

### SCRIPT TO MAKE A "BLOCKED" FASTA INTO AN "UNBLOCKED" ONE
BLOCK2UNBLOCK_FP="/home/leej39/small_tree/block2unblock.R"

### BLAST PARAMETERS
BLAST_EVALUE=1e-5
BLAST_OUTFMT=7
BLAST_DB="/home/leej39/blastdb/LTP"
BLAST_NUM_THREADS=4

###=====================
### MAKE AN "UNBLOCKED" VERSION OF THE QUERY FASTA
###=====================

Rscript --vanilla ${BLOCK2UNBLOCK_FP} ${QUERY_FASTA}
UNBLOCKED_QUERY_FASTA=$(dirname ${QUERY_FASTA})"/unblocked_"$(basename ${QUERY_FASTA})

###=====================
### BLAST AGAINST THE DATABASE
###=====================

BLAST_OUT_FP="${QUERY_FASTA}.blastout"
blastn -evalue ${BLAST_EVALUE} -outfmt ${BLAST_OUTFMT} -db ${BLAST_DB} -query ${UNBLOCKED_QUERY_FASTA} -num_threads ${BLAST_NUM_THREADS} -out ${BLAST_OUT_FP}




