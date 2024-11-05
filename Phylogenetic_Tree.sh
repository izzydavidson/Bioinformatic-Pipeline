#!/bin/bash
# Retrieve Accession Numbers off SILVA Database website & Download FASTA Sequence

# Decompress File

tar -xvzf VMBMicrobes.tgz -C /path/to/directory

# Align Sequences with ClustalW. Has to be in Infile Dir

clustalw -INFILE=lactospp.fasta -TYPE=DNA -OUTFILE=lactobacillus_aligned.aln

# Convert .aln File to .MEG File Via MEGA-CC (Non-Terminal/Desktop Version)

# Create Phylogenetic Tree in MEGA-CC (Has to be in Dir where infer file is)

megacc -a infer_NJ_nucleotide.mao -d /mnt/Study_2_pipeline/Study2pipeline/phylogenic_tree/lactobacillus_aligned.meg -o /mnt/Study_2_pipeline/Study2pipeline/phylogenic_tree/lactobacillus_tree.nwk -t 1

# Visualise Tree Via FigTree

java -jar /mnt/Study_2_pipeline/Study2pipeline/phylogenic_tree/FigTree_v1.4.4/lib/figtree.jar -graphic PDF VMB_tree.nwk  /mnt/Study_2_pipeline/Study2pipeline/phylogenic_tree/VMB_Microbes/VMB_Microbes.pdf 

