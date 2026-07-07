# Competitive Metagenomic Read Recruitment Workflow

This repository provides an automated, reproducible workflow for competitive metagenomic read recruitment using the Anvi'o platform (version 9). Read recruitment is a cornerstone of metagenomics, allowing researchers to quantify the abundance, detection, and genomic variation of specific microbial strains or species across diverse environmental samples.

## Computational and Biological Rationale

In metagenomic studies, mapping sequencing reads to a single reference genome in isolation often yields high false-positive rates due to highly conserved genes and genomic regions shared among closely related taxa. Competitive read recruitment addresses this limitation by aligning metagenomic reads against a single, co-indexed database containing multiple reference genomes simultaneously. 

By presenting all reference genomes together during the alignment phase, homologous reads are forced to align to the most specific reference sequence. Reads from highly conserved regions will either map to the genome with the highest sequence identity or be flagged as multi-mapped (low mapping quality), preventing the false detection of genomes that are not truly present in the sample. This competitive approach yields highly accurate estimates of genome coverage, detection, and relative abundance.

## Workflow Pipeline Architecture

The pipeline is implemented using the Snakemake execution engine integrated within Anvi'o. The workflow proceeds through five main phases:

1. **Defline Reformatting**: Contig headers of all input reference genomes are simplified and prefixed with their respective genome names. This step is critical because standard FASTA headers from databases like NCBI can contain spaces and special characters that disrupt downstream mapping tools, and the prefix allows contigs to be tracked back to their source genomes.
2. **Database and Collection Preparation**: The reformatted FASTA files are concatenated into a single co-indexed reference file, and a collection mapping file is generated to link each contig to its parent genome.
3. **Metagenomic Mapping**: Metagenomic reads are aligned against the concatenated reference database using Bowtie2. The resulting SAM files are converted into coordinate-sorted and indexed BAM files using Samtools.
4. **Anvi'o Profiling**: Anvi'o profiles each BAM file individually to calculate coverage, detection, and sequence variation (such as single-nucleotide variants) for every contig.
5. **Merging and Summarization**: Single-sample profiles are merged into a unified profile database. The collection mapping is imported, and the final results are summarized into an interactive HTML report and tab-delimited tables.

## Repository Directory Structure

The repository maintains a strict directory structure to separate source code, configuration files, and data types. Below is the synchronized layout of the project:

* **README.md**: Scholarly overview, rationale, and instructions for the workflow.
* **license**: Software licensing terms.
* **scripts/**: Shell scripts for environment setup and workflow execution.
  * **installation.sh**: Installs the Anvi'o conda environment and dependencies.
  * **analysis.sh**: Executes the end-to-end read recruitment pipeline.
  * **KEGG_archive_unpacked/**: Place for unpacked KEGG functional databases.
* **MRR/**: Metagenomic Read Recruitment workspace (generated during execution).
  * **GENOMES/**: Placeholder for reference genome FASTA files.
  * **METAGENOMES/**: Placeholder for raw or filtered paired-end FASTQ reads.
  * **00_LOGS/**: Log files for Snakemake execution.
  * **01_QC/**: Read quality control outputs.
  * **03_CONTIGS/**: Contigs database and HMM annotations.
  * **04_MAPPING/**: Bowtie2 index files and sample BAM files.
  * **05_ANVIO_PROFILE/**: Individual sample profiles.
  * **06_MERGED/**: Merged profiling database.
  * **SUMMARY/**: Final summarized tables, figures, and HTML reports.

## Installation and Setup

The workflow requires Conda or Mamba to manage dependencies. To install the required software and set up the Anvi'o v9 environment, execute the installation script:

```bash
bash scripts/installation.sh
```

This script performs the following steps:
1. Detects the package manager (preferring Mamba, falling back to Conda).
2. Creates a dedicated Python 3.10 environment named `anvio-9`.
3. Installs core bioinformatics dependencies (including Bowtie2, Samtools, Megahit, and Snakemake).
4. Installs the Anvi'o v9 package.
5. Downloads and initializes standard taxonomic and functional database headers.
6. Verifies the installation using the Anvi'o mini suite self-test.

## Execution Workflow

Before running the analysis, configure the variables in `scripts/analysis.sh` under the configuration section:

* `project`: The name of the project folder (defaults to `MRR`).
* `threads`: Number of threads to assign to individual rules.
* `max_threads`: Maximum threads to allocate for the Snakemake run.
* `use_hpc`: Set to `true` if submitting to a Slurm HPC cluster.

To execute the workflow locally, run:

```bash
bash scripts/analysis.sh
```

This script will automatically download the test dataset (two reference genomes and three metagenomic samples), prepare the database files, run the alignment and profiling rules, and compile the final summary.

## Outputs and Downstream Analysis

Upon successful completion, key outputs can be found in the following directories:

* **Contigs Database** (`MRR/03_CONTIGS/MRR-contigs.db`): Stores the sequence data, open reading frames, and HMM search hits.
* **Merged Profile Database** (`MRR/06_MERGED/MRR/PROFILE.db`): The central database containing mapping stats across all samples.
* **Summary Directory** (`MRR/SUMMARY/`): Contains `index.html`, which can be opened in a web browser to view interactive plots of genome coverage, detection, and relative abundance.

To inspect the results interactively within the Anvi'o visualizer, run:

```bash
conda activate anvio-9
anvi-interactive -p MRR/06_MERGED/MRR/PROFILE.db \
                 -c MRR/03_CONTIGS/MRR-contigs.db \
                 -C GENOMES
```
