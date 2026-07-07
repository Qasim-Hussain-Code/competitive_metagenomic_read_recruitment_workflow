#!/usr/bin/env bash
# =============================================================================
# Competitive Metagenomic Read Recruitment: anvi'o Workflow Script
# Tutorial: https://anvio.org/tutorials/competitive-read-recruitment/
#
# PREREQUISITES:
#   - conda installed (https://docs.conda.io/en/latest/miniconda.html)
#   - anvi'o installed in a conda environment named 'anvio-9'
#     (see: https://anvio.org/install/)
#
# DATA USED (downloaded automatically):
#   Genomes (anvi'o test sandbox on GitHub):
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/G01-contigs.fa.gz
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/G02-contigs.fa.gz
#
#   Metagenomes (anvi'o test sandbox on GitHub):
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/sample-01-R1.fastq.gz
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/sample-01-R2.fastq.gz
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/sample-02-R1.fastq.gz
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/sample-02-R2.fastq.gz
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/sample-03-R1.fastq.gz
#     https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/sample-03-R2.fastq.gz

set -euo pipefail  

# =============================================================================
# CONFIGURATION
# =============================================================================

export project="MRR"         
export workdir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  
export threads=4                    
export max_threads=4                 
export use_hpc="false"               
                       

# =============================================================================
# Activate anvi'o conda environment
# =============================================================================
if command -v conda &>/dev/null; then
    eval "$(conda shell.bash hook)"
    conda activate anvio-9
else
    echo "ERROR: conda not found. Please install Miniconda first: https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

# =============================================================================
# STEP 0: Verify anvi'o is installed
# =============================================================================
echo "============================================================"
echo " Checking anvi'o installation..."
echo "============================================================"
anvi-run-workflow -v || { echo "ERROR: anvi'o not found. Please install it first."; exit 1; }

# =============================================================================
# STEP 1: General setup: create project directory
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 1: Setting up project directory"
echo "============================================================"

cd "$workdir"
mkdir -p "$project"
cd "$project"
echo "Working directory: $(pwd)"

# =============================================================================
# STEP 2: Set up reference genome FASTA files
#
# Your .fa genome files should already be in GENOMES/ at this point.
# If you have contigs-db files instead, uncomment the export loop below.
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 2: Preparing reference genome FASTA files"
echo "============================================================"

mkdir -p GENOMES

# Download tutorial reference genomes from the anvi'o GitHub repository
# URLs: https://github.com/merenlab/anvio/tree/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example
echo "  Downloading tutorial genomes from anvi'o GitHub..."
wget -q -O GENOMES/G01.fa.gz \
    "https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/G01-contigs.fa.gz"
wget -q -O GENOMES/G02.fa.gz \
    "https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/G02-contigs.fa.gz"
gzip -d GENOMES/G01.fa.gz GENOMES/G02.fa.gz
echo "  Downloaded: GENOMES/G01.fa and GENOMES/G02.fa"

# -- If you have contigs-db files, uncomment to export them as FASTA --
# for i in *.db; do
#     genome_name=$(echo "$i" | sed 's/-contigs.db//g')
#     anvi-export-contigs -c "${genome_name}-contigs.db" -o "GENOMES/${genome_name}.fa"
# done

# Verify FASTA files exist
fa_count=$(ls GENOMES/*.fa 2>/dev/null | wc -l)
if [[ "$fa_count" -eq 0 ]]; then
    echo "ERROR: No .fa files found in GENOMES/."
    echo "       Please place your genome FASTA files (*.fa) in: $(pwd)/GENOMES/"
    exit 1
fi
echo "Found $fa_count genome FASTA file(s) in GENOMES/"

# =============================================================================
# STEP 3: Fix deflines: rename sequences with genome-name prefix
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 3: Reformatting FASTA deflines (simplify + add prefix)"
echo "============================================================"

cd GENOMES

for i in *.fa; do
    genome_name=$(basename "$i" .fa)
    echo "  Reformatting: $genome_name"
    anvi-script-reformat-fasta "$i" \
                               --simplify-names \
                               --prefix "$genome_name" \
                               --report-file "${genome_name}_RENAME.txt" \
                               --overwrite-input
done

echo ""
echo "  Preview of sequence names in the last genome processed ($genome_name):"
grep '>' "$genome_name.fa" | head -n 10

cd ..

# =============================================================================
# STEP 4: Generate collection.txt
# Maps every contig back to the genome it came from
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 4: Generating collection.txt"
echo "============================================================"

for i in GENOMES/*.fa; do
    genome_name=$(basename "$i" .fa)
    while IFS= read -r line; do
        [[ "$line" == ">"* ]] && echo -e "${line:1}\t${genome_name}"
    done < "$i"
done > collection.txt

echo "  First 10 lines of collection.txt:"
head -n 10 collection.txt
echo "  ..."
echo "  Last 10 lines of collection.txt:"
tail -n 10 collection.txt

# =============================================================================
# STEP 5: Concatenate all genomes into one competitive FASTA file
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 5: Concatenating all genomes into ${project}.fa"
echo "============================================================"

cat GENOMES/*.fa > "${project}.fa"
echo "  Created: ${project}.fa"

# =============================================================================
# STEP 6: Generate fasta.txt (reference FASTA manifest)
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 6: Generating fasta.txt"
echo "============================================================"

echo -e "name\tpath\n${project}\t$(pwd)/${project}.fa" > fasta.txt
echo "  Contents of fasta.txt:"
cat fasta.txt

# =============================================================================
# STEP 7: Generate samples.txt (metagenome manifest)
#
# samples.txt must have exactly 3 TAB-separated columns:
#   sample   r1   r2
#
# Edit the heredoc below to list your metagenome samples.
# Rules:
#   - Sample names: letters and underscores only, cannot start with a digit
#   - r1/r2: absolute paths to paired-end FASTQ files (can be gzipped)
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 7: Generating samples.txt"
echo "============================================================"

# Download tutorial metagenomes from the anvi'o GitHub repository
# URLs: https://github.com/merenlab/anvio/tree/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example
mkdir -p METAGENOMES
echo "  Downloading tutorial metagenomes from anvi'o GitHub..."
for sample in sample-01 sample-02 sample-03; do
    wget -q -O "METAGENOMES/${sample}-R1.fastq.gz" \
        "https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/${sample}-R1.fastq.gz"
    wget -q -O "METAGENOMES/${sample}-R2.fastq.gz" \
        "https://raw.githubusercontent.com/merenlab/anvio/master/anvio/tests/sandbox/workflows/metagenomics/three_samples_example/${sample}-R2.fastq.gz"
done
echo "  Downloaded 3 paired-end metagenome samples into METAGENOMES/"

cat > samples.txt << EOF
sample	r1	r2
sample_01	$(pwd)/METAGENOMES/sample-01-R1.fastq.gz	$(pwd)/METAGENOMES/sample-01-R2.fastq.gz
sample_02	$(pwd)/METAGENOMES/sample-02-R1.fastq.gz	$(pwd)/METAGENOMES/sample-02-R2.fastq.gz
sample_03	$(pwd)/METAGENOMES/sample-03-R1.fastq.gz	$(pwd)/METAGENOMES/sample-03-R2.fastq.gz
EOF

echo "  Contents of samples.txt:"
cat samples.txt

# Validate column count
col_count=$(awk 'BEGIN{FS="\t"}{print NF}' samples.txt | sort | uniq)
if [[ "$col_count" != "3" ]]; then
    echo "ERROR: samples.txt must have exactly 3 tab-separated columns. Found: $col_count"
    exit 1
fi

# Check all metagenome files exist
echo ""
echo "  Checking metagenome file paths..."
all_file_paths=$(awk 'BEGIN{FS="\t"}{if(NR>1){ print $2 "\n" $3}}' samples.txt)
missing=0
for file_path in $all_file_paths; do
    if [[ ! -f "$file_path" ]]; then
        echo "  MISSING: $file_path"
        missing=$((missing + 1))
    fi
done
if [[ "$missing" -gt 0 ]]; then
    echo "WARNING: $missing metagenome file(s) are missing. Update samples.txt before running the workflow."
else
    echo "  All metagenome files found."
fi

# =============================================================================
# STEP 8: Generate and configure the workflow config file (config.json)
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 8: Generating and configuring config.json"
echo "============================================================"

# Generate default config
anvi-run-workflow -w metagenomics --get-default-config config.json
echo "  Default config.json generated."

# Apply required edits using sed:
#   1) Set references_mode to true  (skip assembly, use our pre-made genomes)
#   2) Disable anvi_script_reformat_fasta (we already fixed deflines in step 3)
#   3) Optionally disable quality filtering
#   4) Set thread count

sed -i 's/"references_mode": ""/"references_mode": true/' config.json

python3 - << 'PYEOF'
import json, os

config_path = "config.json"
with open(config_path) as f:
    cfg = json.load(f)

# Required: use pre-made references, skip assembly
cfg["references_mode"] = True

# Required: do not re-reformat FASTA (we already did it)
if "anvi_script_reformat_fasta" in cfg:
    cfg["anvi_script_reformat_fasta"]["run"] = False

# Optional: disable quality filtering if reads are already filtered
run_qc_env = os.environ.get("run_qc", "false").lower()
if run_qc_env == "false" and "iu_filter_quality_minoche" in cfg:
    cfg["iu_filter_quality_minoche"]["run"] = False

# Set thread counts
threads = int(os.environ.get("threads", 4))
max_threads = int(os.environ.get("max_threads", 4))
if "max_threads" in cfg:
    cfg["max_threads"] = max_threads

for rule in cfg.values():
    if isinstance(rule, dict) and "threads" in rule:
        rule["threads"] = threads

with open(config_path, "w") as f:
    json.dump(cfg, f, indent=4)

print("  config.json updated successfully.")
PYEOF

# =============================================================================
# STEP 9: Sanity-check the workflow (generates workflow.pdf)
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 9: Sanity-checking the workflow (generates workflow.pdf)"
echo "============================================================"

anvi-run-workflow -w metagenomics \
                  -c config.json \
                  --save-workflow-graph
echo "  Workflow graph saved. Open workflow.pdf to review the planned steps."

# =============================================================================
# STEP 10: Run the workflow
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 10: Running the metagenomics workflow"
echo "============================================================"

if [[ "$use_hpc" == "true" ]]; then
    # ---- HPC / Slurm submission ----
    cat > 00_RUN.sh << EOF
#!/usr/bin/env bash
anvi-run-workflow -w metagenomics \\
                  -c config.json \\
                  --additional-params \\
                      --cluster \\
                          'sbatch \\
                              --job-name=${project}-{rule} \\
                              --output={log} \\
                              --error={log} \\
                              --partition=${hpc_partition} \\
                              --ntasks-per-node={threads} \\
                              --mem-per-cpu=20000' \\
                      --jobs ${hpc_max_jobs} \\
                      --resource nodes=${hpc_nodes} \\
                      --latency-wait 100 \\
                      --rerun-incomplete
EOF
    echo "  HPC submission script written to 00_RUN.sh"
    echo "  Submit it with:  bash 00_RUN.sh"
    echo "  (Tip: wrap with 'clusterize' or 'nohup' so the session can close safely)"
else
    # ---- Local run ----
    anvi-run-workflow -c config.json \
                      -w metagenomics
    echo "  Workflow complete!"
fi

# =============================================================================
# STEP 11 (post-workflow): Verify output structure
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 11: Checking expected output directories"
echo "============================================================"

for d in 00_LOGS 01_QC 03_CONTIGS 04_MAPPING 05_ANVIO_PROFILE 06_MERGED; do
    if [[ -d "$d" ]]; then
        echo "  [OK] $d"
    else
        echo "  [MISSING] $d - workflow may not have finished yet"
    fi
done

# Quick database info
if [[ -f "03_CONTIGS/${project}-contigs.db" ]]; then
    echo ""
    echo "  --- Contigs DB info ---"
    anvi-db-info "03_CONTIGS/${project}-contigs.db"
fi

if [[ -f "06_MERGED/${project}/PROFILE.db" ]]; then
    echo ""
    echo "  --- Profile DB info ---"
    anvi-db-info "06_MERGED/${project}/PROFILE.db"
fi

# =============================================================================
# STEP 12: Import the genome collection into the merged profile DB
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 12: Importing genome collection"
echo "============================================================"

anvi-import-collection collection.txt \
                       -p "06_MERGED/${project}/PROFILE.db" \
                       -c "03_CONTIGS/${project}-contigs.db" \
                       -C GENOMES \
                       --contigs-mode

# Verify collection was imported
anvi-show-collections-and-bins -p "06_MERGED/${project}/PROFILE.db"

# =============================================================================
# STEP 13: Summarize results
# =============================================================================
echo ""
echo "============================================================"
echo " STEP 13: Summarizing results"
echo "============================================================"

anvi-summarize -p "06_MERGED/${project}/PROFILE.db" \
               -c "03_CONTIGS/${project}-contigs.db" \
               -C GENOMES \
               -o SUMMARY

echo ""
echo "============================================================"
echo " All done!"
echo "  Project     : $project"
echo "  Directory   : $(pwd)"
echo "  Summary     : $(pwd)/SUMMARY"
echo "  Profile DB  : 06_MERGED/${project}/PROFILE.db"
echo "  Contigs DB  : 03_CONTIGS/${project}-contigs.db"
echo ""
echo "  Open the summary in a browser, or explore with anvi-interactive:"
echo "    anvi-interactive -p 06_MERGED/${project}/PROFILE.db \\"
echo "                     -c 03_CONTIGS/${project}-contigs.db \\"
echo "                     -C GENOMES"
echo "============================================================"
