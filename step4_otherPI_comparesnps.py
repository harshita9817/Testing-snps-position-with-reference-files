# comparesnps2.py
import subprocess

ref_vcf = "Filtered_SAP.vcf"
vcf_table = "vcf_paths_all_LN.txt"
ref_list_file = "ref_accessions.txt"

# Load all reference accessions
with open(ref_list_file) as f:
    ref_pis = [line.strip() for line in f if line.strip()]

# Print header
print("PI_random,PI_ref,BothRef,BothAlt,Disagree,Missing,MissingRate,AgreementRate")

# Loop through each random PI and its VCF path
with open(vcf_table) as f:
    for line in f:
        if not line.strip():
            continue
        pi_random, vcf_path = line.strip().split()

        # Compare against every reference PI
        for pi_ref in ref_pis:
            try:
                result = subprocess.run(
                    [
                        "python", "compare_snps53.py",
                        "-r", ref_vcf,
                        "-c", vcf_path,
                        "-p", pi_random,
                        "-q", pi_ref
                    ],
                    capture_output=True,
                    text=True
                )
                lines = result.stdout.strip().split("\n")
                if len(lines) > 1 and "ERROR" not in lines[1] and "FAILED" not in lines[1]:
                    print(lines[1])
                else:
                    print(f"{pi_random},{pi_ref},ERROR,ERROR,ERROR,ERROR,ERROR,ERROR")
            except Exception:
                print(f"{pi_random},{pi_ref},FAILED,FAILED,FAILED,FAILED,FAILED,FAILED")
