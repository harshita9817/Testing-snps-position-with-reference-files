import subprocess

# Define path to reference VCF
ref_vcf = "Filtered_SAP.vcf"

# Print the CSV header once
print("PI,BothRef,BothAlt,Disagree,Missing,MissingRate,AgreementRate")

# Read accession IDs and their corresponding VCF paths
with open("vcf_paths.txt") as f:
    for line in f:
        if line.strip():
            accession, vcf_path = line.strip().split()
            try:
                # Run compare_snps.py and capture the output
                result = subprocess.run(
                    [
                        "python", "compare_snps.py",
                        "-r", ref_vcf,
                        "-c", vcf_path,
                        "-p", accession
                    ],
                    capture_output=True,
                    text=True
                )
                # Extract the result line (skip the header)
                lines = result.stdout.strip().split("\n")
                if len(lines) > 1:
                    print(lines[1])
                else:
                    print(f"{accession},ERROR,ERROR,ERROR,ERROR,ERROR,ERROR")
            except Exception as e:
                print(f"{accession},FAILED,FAILED,FAILED,FAILED,FAILED,FAILED")
