#!/bin/bash
###########################################################################################################################################################################################################

### Fast5 files require converting to a PDO5 file prior to basecalling

#pod5 convert fast5 '/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/Run3/RUN 3' -o '/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/Run3/rawrun3'

# If error message occurs about no mutli-read format, convert single-read files to multi-read files via:

#single_to_multi_fast5 -i /mnt/Study_2_pipeline/Study2pipeline/nextflow/data/Run3/'RUN 3' -s /mnt/Study_2_pipeline/Study2pipeline/nextflow/data/Run3/rawrun3/

#Dorado Basecaller

#dorado basecaller --device cpu dna_r10.4.1_e8.2_260bps_hac@v4.0.0/ /mnt/data/Study2pipeline/nextflow/dorado_dir/PDO5_files/ > run4.bam

#Dorado Duplex Run:
#cd /mnt/Study_2_pipeline/Study2pipeline/nextflow/dorado/dorado_dir


/mnt/Study_2_pipeline/Study2pipeline/nextflow/dorado/dorado_stuff/dorado-0.4.1-linux-x64/bin/dorado duplex --device cpu dna_r10.4.1_e8.2_260bps_hac@v4.0.0/ /mnt/Study_2_pipeline/Study2pipeline/nextflow/dorado/VMB_Run1/POD5_Files > VMBrun1calls.bam

# Check the files

samtools quickcheck /mnt/Study_2_pipeline/Study2pipeline/nextflow/dorado/VMBrun1calls.bam

# Converting .bam to .fastq
samtools bam2fq VMBrun1calls.bam > VMBrun1.fastq

# Move .fastq file to new directory

sudo mv VMBrun1.fastq /mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/Raw_files

# Change Directory back
cd /mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/

###  Quality reports and checks-raw data    ###
#----------------------------------------------#

# Specify the directory containing your FASTQ files
input_dir="/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/Raw_files"

# Specify the output directory for filtered files
output_dir="/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/FastQC"

# Run FastQC on all Nanopore FASTQ files in the input directory
fastqc --nano  -o "$output_dir" --extract "$input_dir"/*.fastq

echo 'FastQC completed. Reports available in nextflow/data/VMBRun1/FastQC'

###  MultiQC-raw data   ###
#--------------------------#

 /usr/bin/multiqc . /mnt/Study_2_pipeline/Study2pipeline/nextflow/data/Run4/FastQC -o "/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/multiqc"

echo 'MultiQC competed. Report will be available in nextflow/data/VMBRun1/multiqc'


###   Adapter Trimming & Demultiplexing - Porechop   ###
#------------------------------------------------------#
/mnt/Study_2_pipeline/Study2pipeline/nextflow/Porechop/porechop-runner.py -i "/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/Raw_files/" -t 4 -b "/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/Trim/"
echo 'Adapters successfully trimmed. Trimmed reads available at nextflow/data/VMBRun1/Trim'

###      NANOclust for filtering, chimera identification/deection and clustering    ####
#--------------------------------------------------------------------------------------#
#Remove Execution Trace

sudo rm /mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/results/pipeline_info/execution_trace.txt


# Limit Memory

NXF_OPTS='-Xms1g -Xmx4g'


#Running NanoCLUST

sudo ../nextflow run main.nf --reads "/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/Trim/*.fastq" --db "/mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/db/16S_ribosomal_RNA" --tax "mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/db/taxdb/" -profile docker  --min_read_length 500 --min_cluster_size 25

echo 'NanoCLUST complete. Data will be stored in nextflow/NanoCLUST/results directory'


###  Quality reports for processed data    ###
#--------------------------------------------#

# Run FastQC on all Nanopore FASTQ files in the input directory
fastqc --nano  -o "/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/p_fastqc" --extract "/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/Trim"/*.fastq

echo 'FastQC completed. Reports available in nextflow/data/p_fastqc'


###  MultiQC processed data   ###
#-------------------------------#

 /usr/bin/multiqc . /mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/p_fastqc -o "/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/VMBRun1/p_multiqc"

echo 'MultiQC competed. Report will be available in nextflow/data/processed_multiqc_data'

cd //mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/results

### Loop To Combine all .csv Files for Data Analysis ####
#-------------------------------------------------------#
results_dir="/mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/results/"
output_dir="$results_dir/compiled_results"
mkdir -p "$output_dir" || { echo "Error: Unable to create output directory"; exit 1; }

# Iterate over subdirectories
for subdir in "$results_dir"/*; do
    # Check if the item is a directory
    if [ -d "$subdir" ]; then
        subdir_name=$(basename "$subdir")  # Get the name of the subdirectory
        output_file="$output_dir/${subdir_name}.csv"  # Define output file name for each subdirectory

        # Check if there are CSV files in the subdirectory
        csv_files=("$subdir"/*.csv)
        if [ ${#csv_files[@]} -eq 0 ]; then
            echo "Warning: No CSV files found in $subdir"
            continue
        fi

        # Initialize the output file with header
        echo "taxid,rel_abundance" > "$output_file"

        # Concatenate all CSV files in the subdirectory into a single file
        cat "${csv_files[@]}" > "$output_file.tmp" || { echo "Error: Failed to concatenate CSV files"; exit 1; }

        # Extract the top 20 most abundant bacteria and append to the output file
        tail -n +2 "$output_file.tmp" | sort -t',' -k2 -nr | head -n 14 >> "$output_file" || { echo "Error: Failed to sort and append to output file"; exit 1; }

        # Remove temporary file
        rm "$output_file.tmp" || { echo "Error: Failed to remove temporary file"; exit 1; }
    fi
done

echo "Top 20 most abundant bacteria files generated in $output_dir"


# Navigate to the directory containing your CSV files
cd /mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/results/compiled_results

# Loop through each CSV file and remove duplicates
for file in *.csv; do
    # Extract the header
    header=$(head -n 1 "$file")
    # Remove duplicates from the CSV file while preserving the header
    awk '!seen[$0]++' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    # Prepend the header back to the file
    echo "$header" > "$file.tmp" && cat "$file" >> "$file.tmp" && mv "$file.tmp" "$file"
done

# Loop through each CSV file and sort alphabetically
for file in *.csv; do
    # Extract the header
    header=$(head -n 1 "$file")
    # Sort the file alphabetically (excluding the header) and save the sorted content to a temporary file
    tail -n +2 "$file" | sort > "$file.sorted"
    # Prepend the header back to the sorted content
    echo "$header" > "$file.sorted.tmp" && cat "$file.sorted" >> "$file.sorted.tmp" && mv "$file.sorted.tmp" "$file.sorted"
    # Overwrite the original file with the sorted content
    mv "$file.sorted" "$file"
done


