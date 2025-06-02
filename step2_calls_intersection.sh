#!/bin/bash
#SBATCH --job-name=parallel_hn
#SBATCH --nodes=1
#SBATCH --array=1-355
#SBATCH --ntasks-per-node=6 #4 #6 #36
#SBATCH --mem=50G #20G #10G #40G #120G #80G #45G #25G #60G #20 #30G
#SBATCH --time=99:00:00
#SBATCH --error=/work/schnablelab/harshita/%2aligntored.err
#SBATCH --output=/work/schnablelab/harshita/%2aligntored.out
#SBATCH --partition=schnablelab
#SBATCH --mail-type=ALL
#SBATCH --mail-user=hmangal2@huskers.unl.edu

ml samtools 
ml bcftools 

# Set paths to required files
BAM_DIR="HNstar_output"
REF="Sbicolor_730_v5.0.fasta"
VCF="Filtered_SAP.vcf.gz"
OUT_DIR="HN_snpcheck"
BAM_LIST="bam_list.txt"

# Get SLURM array index or fallback
# Get SLURM array index or fallback
TASK_ID=${SLURM_ARRAY_TASK_ID:-1}

# Get BAM file and sample name
bam=$(sed -n "${TASK_ID}p" "$BAM_LIST")
sample=$(basename "$bam" .sorted.bam)

echo "[${TASK_ID}] Processing $sample"

# Call variants: include both REF and ALT alleles
bcftools mpileup -f "$REF" -T "$VCF" -Ou "$bam" --threads 8 | \
bcftools call -m -Ov -o "$OUT_DIR/${sample}_called.vcf" --threads 8

# Compress and index the VCF
bgzip -f "$OUT_DIR/${sample}_called.vcf"
tabix -p vcf "$OUT_DIR/${sample}_called.vcf.gz"

# Set path to already-created compressed VCF
called_vcf="$OUT_DIR/${sample}_called.vcf.gz"

# Check if called VCF exists
if [ ! -f "$called_vcf" ]; then
    echo "[${TASK_ID}] Missing $called_vcf. Skipping."
    exit 1
fi

# Trim first 10 characters from sample name
trimmed_sample="${sample:10}"

# Create intersection directory
isec_dir="$OUT_DIR/${sample}_isec"
mkdir -p "$isec_dir"

# Run intersection with imputed VCF
bcftools isec -n=2 -c all -w1 -Ov -p "$isec_dir" "$called_vcf" "$VCF"
# Count SNPs in sample-called VCF (both REF and ALT present)
snps_bam=$(zgrep -vc "^#" "$called_vcf")

# Count SNPs in imputed VCF
snps_vcf=$(zgrep -vc "^#" "$VCF")

# Count overlapping SNPs
if [ -f "$isec_dir/0000.vcf" ]; then
    snps_both=$(grep -vc "^#" "$isec_dir/0000.vcf")
else
    snps_both=0
fi

# Summary file path
summary="$OUT_DIR/snp_overlap_summary.csv"

# Write header only once
if [ "$TASK_ID" -eq 1 ] && [ ! -f "$summary" ]; then
    echo "sample,snps_in_bam,snps_in_vcf,snps_in_both" > "$summary"
fi

# Append results to summary
echo "${trimmed_sample},$snps_bam,$snps_vcf,$snps_both" >> "$summary"

echo "[${TASK_ID}] Done $sample"
