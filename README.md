python3 -m venv myenv
source myenv/bin/activate
pip install PyVCF
python comparesnps2.py Filtered_SAP.vcf vcf_paths.txt
