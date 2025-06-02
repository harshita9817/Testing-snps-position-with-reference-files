#!/bin/bash
#SBATCH --job-name=24-aligntoref
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=36 #4 #6 #36
#SBATCH --mem=50G #20G #10G #40G #120G #80G #45G #25G #60G #20 #30G
#SBATCH --time=99:00:00
#SBATCH --error=/work/schnablelab/harshita/Nitrogen_response_project/log2/%2aligntored.err
#SBATCH --output=/work/schnablelab/harshita/Nitrogen_response_project/log2/%2aligntored.out
#SBATCH --partition=schnablelab
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hmangal2@huskers.unl.edu

ml samtools
#ml bwa
ml star

cd /work/schnablelab/harshita/Nitrogen_response_project/out.trimm

for i in *1_paired.fastq.gz; do 
    base=$(basename "$i" 1_paired.fastq.gz)

    output_bam="/work/schnablelab/harshita/Nitrogen_response_project/output_star/${base}.sorted.bam"
    output_bai="${output_bam}.bai"

    # Skip if the final BAM index already exists
    if [[ -f "$output_bai" ]]; then
        echo "Skipping $base — already processed."
        continue
    fi

    echo "Processing $base..."

    STAR --runThreadN 24 \
         --genomeDir /work/schnablelab/harshita/Nitrogen_response_project/genomeDir/ \
         --outSAMmultNmax 1 \
         --outFileNamePrefix /scratch/${base} \
         --readFilesCommand gunzip -c \
         --readFilesIn ${base}1_paired.fastq.gz ${base}2_paired.fastq.gz

    samtools sort -@ 24 -m 2G /scratch/${base}Aligned.out.sam -o /scratch/${base}.sorted.bam

    cp /scratch/${base}.sorted.bam /work/schnablelab/harshita/Nitrogen_response_project/output_star/

    rm /scratch/${base}Aligned.out.sam 
    rm /scratch/${base}.sorted.bam

    samtools index "$output_bam"

done
