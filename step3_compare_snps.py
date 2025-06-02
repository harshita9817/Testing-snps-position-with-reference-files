import argparse
import os
import sys

parser = argparse.ArgumentParser()
parser.add_argument("-r", "--refvcf", help="path to reference VCF file")
parser.add_argument("-c", "--rnavcf", help="path to RNA VCF file of sample")
parser.add_argument("-p", "--piid", help="name of sorghum accession")
args = parser.parse_args()

if not os.path.exists(args.refvcf):
    sys.exit(f"No such file: {args.refvcf}")

# Step 1: Load reference VCF
ref_snp_dict = {}
with open(args.refvcf) as fh:
    for line in fh:
        if line.startswith("##"):
            continue
        elif line.startswith("#"):
            header = line.strip().split("\t")
            header_to_index = {val: idx for idx, val in enumerate(header)}
            if args.piid not in header_to_index:
                sys.exit(f"The sorghum accession you provided -- {args.piid} -- was not found in the reference file")
        else:
            fields = line.strip().split("\t")
            snp_id = f"{fields[0]}_{fields[1]}"
            ref_field = fields[header_to_index[args.piid]]
            ref_gt = ref_field.split(":")[0].replace("/", "|")  # normalize
            ref_snp_dict[snp_id] = ref_gt

# Step 2: Compare to RNA VCF
ref_agree = 0
alt_agree = 0
disagree = 0
missing = 0

with open(args.rnavcf) as fh:
    for line in fh:
        if line.startswith("#"):
            continue
        fields = line.strip().split("\t")
        snp_id = f"{fields[0]}_{fields[1]}"
        rna_gt = fields[-1].split(":")[0].replace("/", "|")

        if rna_gt == ".|.":
            missing += 1
            continue

        ref_gt = ref_snp_dict.get(snp_id)
        if ref_gt is None or ref_gt == ".|.":
            missing += 1
        elif rna_gt == "0|0" and ref_gt == "0|0":
            ref_agree += 1
        elif rna_gt == "1|1" and ref_gt == "1|1":
            alt_agree += 1
        else:
            disagree += 1

# Step 3: Output
total_called = ref_agree + alt_agree + disagree
missing_rate = missing / (total_called + missing) if (total_called + missing) > 0 else 0
agreement_rate = (ref_agree + alt_agree) / total_called if total_called > 0 else 0

print("PI,BothRef,BothAlt,Disagree,Missing,MissingRate,AgreementRate")
print(",".join(map(str, [
    args.piid,
    ref_agree,
    alt_agree,
    disagree,
    missing,
    round(missing_rate, 6),
    round(agreement_rate, 6)
])))
