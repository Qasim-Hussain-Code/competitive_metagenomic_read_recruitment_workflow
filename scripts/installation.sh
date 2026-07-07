#!/bin/bash
# ---------------------------------------------------------------
# Installation script for anvi'o v9 and all required dependencies
# ---------------------------------------------------------------
set -e

# Check if mamba or conda is available
if command -v mamba &>/dev/null; then
    PACKAGE_MGR="mamba"
elif command -v conda &>/dev/null; then
    echo "WARNING: mamba not found, falling back to conda. This process might be slower."
    PACKAGE_MGR="conda"
else
    echo "ERROR: Neither mamba nor conda was found. Please install Conda first: https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

# 1. Create a dedicated conda environment
conda create -y --name anvio-9 python=3.10

# 2. Activate the environment
#    (conda activate requires shell initialization inside scripts)
eval "$(conda shell.bash hook)"
conda activate anvio-9

# 3. Install core dependencies
#    NOTE: snakemake is required for anvi-run-workflow
$PACKAGE_MGR install -y -c conda-forge -c bioconda python=3.10 \
        sqlite=3.46 prodigal idba mcl muscle=3.8.1551 famsa hmmer diamond \
        blast megahit spades bowtie2 bwa graphviz "samtools>=1.9" \
        trimal iqtree trnascan-se fasttree vmatch r-base r-tidyverse \
        r-optparse r-stringi r-magrittr bioconductor-qvalue meme ghostscript \
        nodejs=20.12.2 llvmlite numba \
        snakemake-minimal

$PACKAGE_MGR install -y -c bioconda fastani

# 4. Download and install anvi'o v9
curl -L https://github.com/merenlab/anvio/releases/download/v9/anvio-9.tar.gz \
        --output anvio-9.tar.gz
pip install anvio-9.tar.gz
rm -f anvio-9.tar.gz

# Verify anvi'o installed correctly
anvi-interactive --version || { echo "ERROR: anvi'o installation failed."; exit 1; }

# 5. Set up required databases for functional annotation
anvi-setup-ncbi-cogs
anvi-setup-scg-taxonomy
anvi-setup-kegg-data

echo "Installation complete. Activate the environment with: conda activate anvio-9"

# 6. Run a quick self-test to verify the installation
anvi-self-test --suite mini
