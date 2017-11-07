#!/bin/bash

if [ $# -ne 1 ]; then
        echo "Usage: $0 QUERY_FASTA"
        exit 1
fi

QUERY_FASTA=$1

LTP_FASTA="/home/leej39/LTP/LTPs128_SSU_unaligned_processed.fasta"
ACCESSION="${QUERY_FASTA}.blastout_filtered_accession_only"
UNBLOCKED_QUERY_FASTA=$(dirname ${QUERY_FASTA})"/unblocked_"$(basename ${QUERY_FASTA})
TREE_INPUT_FASTA_FP="${QUERY_FASTA}.tree_input"
TREE_INPUT_QZA_FP="${QUERY_FASTA}.tree_input.qza"
ALIGNED_TREE_INPUT_FP="${QUERY_FASTA}.aligned_tree_input.qza"
MASKED_TREE_INPUT_FP="${QUERY_FASTA}.masked_aligned_tree_input.qza"
UNROOTED_TREE_FP="${QUERY_FASTA}.unrooted_tree.qza"
ROOTED_TREE_FP="${QUERY_FASTA}.rooted_tree.qza"

grep -A 1 --no-group-separator -Fwf ${ACCESSION} ${LTP_FASTA} > ${TREE_INPUT_FASTA_FP}
cat ${UNBLOCKED_QUERY_FASTA} >> ${TREE_INPUT_FASTA_FP}

qiime tools import \
 --input-path ${TREE_INPUT_FASTA_FP} \
 --output-path ${TREE_INPUT_QZA_FP} \
 --type 'FeatureData[Sequence]'

qiime alignment mafft \
  --i-sequences ${TREE_INPUT_QZA_FP} \
  --o-alignment ${ALIGNED_TREE_INPUT_FP} \

qiime alignment mask \
  --i-alignment ${ALIGNED_TREE_INPUT_FP} \
  --o-masked-alignment ${MASKED_TREE_INPUT_FP}

qiime phylogeny fasttree \
  --i-alignment ${MASKED_TREE_INPUT_FP} \
  --o-tree ${UNROOTED_TREE_FP}

qiime phylogeny midpoint-root \
  --i-tree ${UNROOTED_TREE_FP} \
  --o-rooted-tree ${ROOTED_TREE_FP}

qiime tools export ${ROOTED_TREE_FP} --output-dir "$(dirname ${QUERY_FASTA})/rooted_tree"
