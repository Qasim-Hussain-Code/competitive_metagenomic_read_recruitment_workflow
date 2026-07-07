[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](license)

# Competitive Metagenomic Read Recruitment Workflow

This repository provides an automated and reproducible computational pipeline for competitive metagenomic read recruitment using the Anvi'o multi-omics platform (version 9). Read recruitment is a fundamental method in molecular microbial ecology that enables the quantification of taxonomic abundance, genome detection, and sequence variation within microbial populations across environmental samples.

## Computational and Biological Rationale

In shotgun metagenomics, aligning sequencing reads to a single reference genome in isolation frequently introduces false-positive signals. This issue is primarily driven by genomic regions that are highly conserved across distinct taxa, such as ribosomal RNA genes, housekeeping genes, and shared metabolic pathways. When mapping reads to target genomes individually, reads originating from related but unrepresented species may incorrectly align to the lone reference.

Competitive read recruitment addresses this challenge by pooling all reference genomes into a single, co-indexed database. During the alignment phase, metagenomic reads map against this joint database, allowing homologous sequences to compete for the best alignment. Reads derived from conserved regions will either align to the reference with the highest sequence identity or be identified as multi-mapped sequences. This competitive profiling drastically reduces false-positive detections and provides highly accurate measurements of coverage, sequence detection, and relative abundance for specific bacterial and archaeal populations.

## Workflow Pipeline Architecture

The pipeline is implemented using the Snakemake workflow management system integrated directly within the Anvi'o framework. The automated workflow proceeds through the following sequential stages:

1. **Header Reformatting**: Contig headers within input reference FASTA files are simplified and prefixed with their respective genome identifiers. This step removes non-standard characters and whitespace that can cause software compatibility issues in downstream tools, while establishing a systematic prefix structure to map contigs back to their source genomes.
2. **Database Compilation**: The reformatted reference genomes are concatenated to construct a single multi-genome reference database, and an associated contig-to-genome mapping file is generated.
3. **Sequence Alignment**: Metagenomic reads are aligned against the concatenated reference database using Bowtie2. The resulting alignments are processed, sorted by genomic coordinates, and indexed into BAM files using Samtools.
4. **Profiling**: Anvi'o profiles each BAM file independently to compute coverage depth, sequence detection limits, and single-nucleotide variants for each contig.
5. **Multi-Sample Merging**: The individual sample profiles are merged into a single database. The contig-to-genome collection mapping is imported to group contigs into their respective genomic bins.
6. **Summarization**: The pipeline summarizes the results to produce comprehensive abundance tables, detection metrics, and interactive HTML visualizations.

## Repository Directory Structure

The repository maintains a structured layout to separate source code, configuration files, and data types:

* **README.md**: Scholarly overview, scientific principles, and instructions.
* **license**: Software licensing terms.
* **scripts/**: Shell scripts for environment configuration and pipeline execution.
  * **installation.sh**: Installs the Anvi'o v9 conda environment and dependencies.
  * **analysis.sh**: Executes the end-to-end read recruitment pipeline.
  * **KEGG_archive_unpacked/**: Directory for functional databases.
* **MRR/**: Metagenomic Read Recruitment workspace.
  * **GENOMES/**: Input reference genome FASTA files.
  * **METAGENOMES/**: Input raw or filtered paired-end FASTQ reads.
  * **00_LOGS/**: Log files for execution.
  * **01_QC/**: Read quality control outputs.
  * **03_CONTIGS/**: Contigs database and HMM annotations.
  * **04_MAPPING/**: Bowtie2 index files and sample BAM files.
  * **05_ANVIO_PROFILE/**: Individual sample profiles.
  * **06_MERGED/**: Merged profiling database.
  * **SUMMARY/**: Final summarized tables, figures, and HTML reports.

## Installation and Setup

The workflow requires Conda or Mamba to manage software dependencies. To install the required packages and configure the Anvi'o v9 environment, run:

```bash
bash scripts/installation.sh
```

This installation script performs the following operations:
1. Detects the package manager (preferring Mamba, falling back to Conda).
2. Creates a dedicated Python 3.10 environment named `anvio-9`.
3. Installs core dependencies including Bowtie2, Samtools, Megahit, and Snakemake.
4. Installs the Anvi'o v9 package.
5. Downloads and initializes standard taxonomic and functional database headers.
6. Verifies the installation using the Anvi'o mini suite self-test.

## Pipeline Execution

To run the analysis, configure the variables in `scripts/analysis.sh` under the configuration section:

* `project`: The name of the project directory (defaults to `MRR`).
* `threads`: Number of threads allocated to individual rules.
* `max_threads`: Maximum threads allocated for the Snakemake run.
* `use_hpc`: Set to `true` if executing on a Slurm HPC cluster.

To execute the workflow locally, run:

```bash
bash scripts/analysis.sh
```

The script automatically downloads the test dataset, prepares the database files, executes the mapping and profiling rules, and compiles the final summary.

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

## References

1. Eren, A. M., Kiefl, E., Shaiber, A., Veseli, I., Miller, S. E., Schechter, M. S., ... & Delmont, T. O. (2021). Community-led, integrated, reproducible multi-omics with anvi’o. *Nature Microbiology*, 6(1), 3-6. doi:10.1038/s41564-020-00834-3
2. Langmead, B., & Salzberg, S. L. (2012). Fast gapped-read alignment with Bowtie 2. *Nature Methods*, 9(4), 357-359. doi:10.1038/nmeth.1923
3. Köster, J., & Rahmann, S. (2012). Snakemake: a scalable bioinformatics workflow engine. *Bioinformatics*, 28(19), 2520-2522. doi:10.1093/bioinformatics/bts480
4. Li, H., Handsaker, B., Wysoker, A., Fennell, T., Ruan, J., Homer, N., ... & Durbin, R. (2009). The sequence alignment/map format and SAMtools. *Bioinformatics*, 25(16), 2078-2079. doi:10.1093/bioinformatics/btp352

## License

This project is licensed under the terms of the MIT License. See the [license](license) file for details.
