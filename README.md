# Bioinformatic-Pipeline
Custom Bioinformatic Pipeline for Taxonomic Identification from Nanopore Sequencing Reads of the 16S rRNA Gene


## List of Downloads
- POD5 converter: `sudo apt install pod5`
- Samtools: `sudo apt install samtools`
- fastqc : `sudo apt install fastqc`
- multiqc : `sudo apt install fastqc`
- Porechop: `sudo apt install porechop`
- Nextflow: [Nextflow](https://nf-co.re/docs/usage/installation)
- NanoCLUST: [NanoCLUST Repository](https://github.com/genomicsITER/NanoCLUST)
- Dorado [https://github.com/nanoporetech/dorado]

### Dorado Basecalling

Fast5 files require converting to a PDO5 file prior to basecalling either using a POD5 converter tool or the online converter provided by ONT. Can either use basecaller or duplex and once the run is complete, use samtools to convert .bam to .fastq


### FastQC and MultiQC for Raw Data Analysis
Fastq files from dorado are fed directly into fastqc and multiqc tool for raw data analysis before porechop.

### Porechop for Adapter Trimming 

For specific adapter and barcode parameters need to go into the porechop directory and edit the adapters.py file and add custom sequences. For example:


`ADAPTERS = [
    Adapter('27F',
            start_sequence=('27F_YM', 'TTTCTGTTGGTGCTGATATTGCAGAGTTTGATYMTGGCTCAG'),
            end_sequence=('1492R_Y', 'ACTTGCCTGTCGCTCTATCTTCGGTTACCTTGTTAYGACT')),`

           ` Adapter('Barcode 1 (forward)',
                    start_sequence=('BC01', 'AAGAAAGTTGTCGGTGTCTTTGTG'),
                    end_sequence=('BC01_rev', 'CACAAAGACACCGACAACTTTCTT')),`

Once changed need to either: 

Re-run the `python3 setup.py` install command after making your change.
Run Porechop not from your installation directory but rather from the source directory: instead of calling porechop instead call `path/to/Porechop/porechop-runner.py`

### Post Analysis FastQC & MultiQC

FastQC & MultiQC again for analysis of processed data

### NanoCLUST for Chimera Identification & Delection, Clustering, Demultiplexing and Filtering
Once porechop has completed. Feed the processed files into the NanoCLUST Pipeline but first Limit Memory.

`NXF_OPTS='-Xms1g -Xmx4g'`

Running NanoCLUST has to be run in the NanoCLUST Directory and make sure the `execution_trace.txt` file is deleted prior to analysis


### Clean up files generated from NanoCLUST
Firstly compile the top 20 most abundant bacteria for each patient into a .csv file.
Once compiled, clean all the files by removing duplicates, keeping column headers and puting all bacteria into alphabetical order.
Once each document has been cleaned, compile all the results into 1 csv file for exporting into R studio.


## R Studio


