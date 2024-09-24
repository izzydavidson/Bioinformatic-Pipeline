#!/bin/bash

# Set the run name 

run_name="VMBRun3_Mix"


# Set the base directory for the run
base_dir="/mnt/Study_2_pipeline/Study2pipeline/nextflow/data/$run_name"

# Create the required directories
mkdir -p "$base_dir/POD5_files"
mkdir -p "$base_dir/raw"
mkdir -p "$base_dir/bam"
mkdir -p "$base_dir/fastqc"
mkdir -p "$base_dir/multiqc"
mkdir -p "$base_dir/Trim"
mkdir -p "$base_dir/p_fastqc"
mkdir -p "$base_dir/p_multiqc"
mkdir -p "$base_dir/nanoclust_results" 
mkdir -p "$base_dir/filtered_fastq"

sudo cp -r /mnt/Study_2_pipeline/Study2pipeline/nextflow/data/POD5_files/* "$base_dir/POD5_files/"


# POD5 Conversion (adjust command as needed for your setup)
# pod5 convert fast5 "<input_directory>" -o "$base_dir/POD5_files"

# Basecalling with Dorado
#dorado basecaller --device cpu dna_r10.4.1_e8.2_260bps_hac@v4.0.0/ "$base_dir/POD5_files" > "$base_dir/bam/${run_name}.bam"

cd /mnt/Study_2_pipeline/Study2pipeline/nextflow/dorado/dorado_dir

# Dorado Duplex Run
/mnt/Study_2_pipeline/Study2pipeline/nextflow/dorado/dorado_stuff/dorado-0.4.1-linux-x64/bin/dorado duplex --device cpu dna_r10.4.1_e8.2_260bps_hac@v4.0.0/ "$base_dir/POD5_files" > "$base_dir/bam/${run_name}_duplex.bam"

# BAM to FASTQ Conversion
samtools bam2fq "$base_dir/bam/${run_name}_duplex.bam" > "$base_dir/raw/${run_name}.fastq"

# FastQC Analysis
sudo fastqc --nano -o "$base_dir/fastqc" --extract "$base_dir/raw/${run_name}.fastq"

# MultiQC Analysis on Raw Data
multiqc "$base_dir/fastqc" -o "$base_dir/multiqc"

# Trimming and filtering reads shorter than 500 bp
cat "$base_dir/raw/${run_name}.fastq" | NanoFilt -l 500 > "$base_dir/filtered_fastq"

# Run Porechop on the filtered reads
/mnt/Study_2_pipeline/Study2pipeline/nextflow/Porechop/porechop-runner.py -i "$base_dir/filtered_fastq" -t 4 -b "$base_dir/Trim"

# FastQC Analysis on Processed Data
fastqc --nano -o "$base_dir/p_fastqc" --extract "$base_dir/Trim/*.fastq"

# MultiQC Analysis on Processed Data
multiqc "$base_dir/p_fastqc" -o "$base_dir/p_multiqc"

cd /mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/

# Running NanoCLUST


nano_clust_results_dir="$base_dir/nanoclust_results"

#Remove Execution Trace

sudo rm /mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/results/pipeline_info/execution_trace.txt


sudo ../nextflow run main.nf --reads "$base_dir/Trim/*.fastq" --db "/mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/db/16S_ribosomal_RNA" --tax "/mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/db/taxdb/" -profile docker --min_read_length 500 --min_cluster_size 25 --polishing_reads 25 --outdir "$base_dir/nanoclust_results"

echo "NanoCLUST complete. Data will be stored in $nano_clust_results_dir"

# Combine and process CSV files in NanoCLUST results directory
cd "$nano_clust_results_dir"

# Create the output directory for combined results
output_dir="$nano_clust_results_dir/compiled_results"
mkdir -p "$output_dir" || { echo "Error: Unable to create output directory"; exit 1; }

# Iterate over subdirectories
for subdir in "$nano_clust_results_dir"/*; do
    # Check if the item is a directory
    if [ -d "$subdir" ]; then
        echo "Processing directory: $subdir"  # Debugging output

        subdir_name=$(basename "$subdir")  # Get the name of the subdirectory
        output_file="$output_dir/${subdir_name}_S.csv"  # Define output file name for each subdirectory

        # Check if there are _S.csv files in the subdirectory
        csv_files=("$subdir"/*_S.csv)
        if [ ${#csv_files[@]} -eq 0 ]; then
            echo "Warning: No _S.csv files found in $subdir"  # Debugging output
            continue
        fi

        echo "Found _S.csv files: ${csv_files[@]}"  # Debugging output

        # Initialize the output file with header
        echo "taxid,rel_abundance" > "$output_file"

        # Concatenate all _S.csv files in the subdirectory into a single file
        cat "${csv_files[@]}" > "$output_file.tmp" || { echo "Error: Failed to concatenate _S.csv files"; exit 1; }

        # Extract the top 9 most abundant bacteria and append to the output file
        tail -n +2 "$output_file.tmp" | sort -t',' -k2 -nr | head -n 9 >> "$output_file" || { echo "Error: Failed to sort and append to output file"; exit 1; }

        # Remove temporary file
        rm "$output_file.tmp" || { echo "Error: Failed to remove temporary file"; exit 1; }
    fi
done

echo "Top 9 most abundant bacteria files generated in $output_dir"

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
