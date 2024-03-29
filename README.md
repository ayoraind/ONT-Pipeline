## Workflow to remove adapter from uncorrected long reads, filter reads, assemble genomes, and error-correct the assemblies.
### Usage

```

======================================================================================
 ONT PIPELINE - RAW READS TO ERROR-CORRECTED ASSEMBLIES: TAPIR Pipeline version 1.0dev
======================================================================================
 The typical command for running the pipeline is as follows:
        nextflow run main.nf --reads "PathToReadFile(s)" --output_dir "PathToOutputDir" 

        Mandatory arguments:
         --reads                        Query fastq.gz file of sequences you wish to supply as input (e.g., "/MIGE/01_DATA/01_FASTQ/T055-8-*.fastq.gz")
         --output_dir                   Output directory to place output files (e.g., "/MIGE/01_DATA/03_ASSEMBLY")
	 	 
        Optional arguments:
	 --valid_mode                   This should be one of "--pacbio-raw", "--pacbio-corr", "--pacbio-hifi", "--nano-raw", "--nano-corr", or "--nano-hq". [Default: "--nano-raw"]
	 --prescreen_genome_size_check  Default value is 2000. This means that any genome with a genome size less than 2000 KB will be excluded.
	 --prescreen_file_size_check	Default value is 5. This means that any genome with a file size less than 5 MB will be excluded.
	 --sequencing_date		E.g 2023-05-25 or 20230525 or 230525 or G230505 or any date format of your choice. Default date is the current date.
         --help                         This usage statement.
         --version                      Version statement

```


## Introduction
This pipeline removes adapters from raw reads (generated from third-generation sequencers), filters reads, assembles and error-corrects genomes.   


## Sample command
An example of a command to run this pipeline is:

```
nextflow run main.nf --reads "Sample_files/*.fastq.gz" --output_dir "test2"
```

## Word of Note
This is an ongoing project at the Microbial Genome Analysis Group, Institute for Infection Prevention and Hospital Epidemiology, Üniversitätsklinikum, Freiburg. The project is funded by BMBF, Germany, and is led by [Dr. Sandra Reuter](https://www.uniklinik-freiburg.de/institute-for-infection-prevention-and-control/microbial-genome-analysis.html).


## Authors and acknowledgment
The TAPIR (Track Acquisition of Pathogens In Real-time) team.
