#!/bin/bash
###########################################################################################################################################################################################################
#BASECALLER?####

###  Quality reports and checks-raw data    ###
#----------------------------------------------#

# Specify the directory containing your FASTQ files
input_dir="/mnt/Study2pipeline/nextflow/data/raw_files"

# Specify the output directory for filtered files
output_dir="/mnt/Study2pipeline/nextflow/data/fastqc_reports"

# Run FastQC on all Nanopore FASTQ files in the input directory
fastqc --nano  -o "$output_dir" --extract "$input_dir"/*.fastq

echo 'FastQC completed. Reports available in nextflow/data/fastqc_reports'

###  MultiQC-raw data   ###
#--------------------------#

multiqc . /mnt/Study2pipeline/nextflow/data/fastqc_reports -o "/mnt/Study2pipeline/nextflow/data/multiqc_data"

echo 'MultiQC competed. Report will be available in nextflow/data/multiqc_data'




###   Adapter Trimming & Demultiplexing - Porechop   ###
#------------------------------------------------------#
 /mnt/Study2pipeline/nextflow/NanoCLUST/porechop_nonspecific/Porechop/porechop-runner.py -i "/mnt/Study2pipeline/nextflow/data/raw_files/" -t 4 -b "/mnt/Study2pipeline/nextflow/data/adapter_trimnon/" 
echo 'Adapters successfully trimmed. Trimmed reads available at nextflow/data/adapter_trimnon'

###      NANOclust for filtering, chimera identification/deection and clustering    ####
#--------------------------------------------------------------------------------------#

# Limit Memory

#NXF_OPTS='-Xms1g -Xmx4g'


#Running NanoCLUST

#sudo ../nextflow run main.nf --reads "/mnt/Study2pipeline/nextflow/data/adapter_trimnon/*.fastq" --db "/mnt/Study2pipeline/nextflow/NanoCLUST/db/16S_ribosomal_RNA" --tax "/mnt/Study2pipeline/nextflow/NanoCLUST/db/taxdb/" -profile docker --min_read_length 1000


#echo 'NanoCLUST complete. Data will be stored in nextflow/NanoCLUST/results directory'


###  Quality reports for processed data    ###
#--------------------------------------------#

# Run FastQC on all Nanopore FASTQ files in the input directory
fastqc --nano  -o "/mnt/Study2pipeline/nextflow/data/processed_fastqc_reports" --extract "/mnt/Study2pipeline/nextflow/data/adapter_trimnon"/*.fastq

echo 'FastQC completed. Reports available in nextflow/data/processed_fastqc_reports'


###  MultiQC processed data   ###
#-------------------------------#

multiqc . /mnt/Study2pipeline/nextflow/data/processed_fastqc_reports -o "/mnt/Study2pipeline/nextflow/data/processed_multiqc_data"

echo 'MultiQC competed. Report will be available in nextflow/data/processed_multiqc_data'

### Loop To Combine all .csv Files for Data Analysis ####
#-------------------------------------------------------#
results_dir="/mnt/Study2pipeline/nextflow/NanoCLUST/results"
output_dir="$results_dir/compiled_results"
mkdir -p "$output_dir"

# Iterate over subdirectories
for subdir in "$results_dir"/*; do
   # Check if the item is a directory
   if [ -d "$subdir" ]; then
       subdir_name=$(basename "$subdir")  # Get the name of the subdirectory
     output_file="$output_dir/${subdir_name}.csv"  # Define output file name for each subdirectory

        # Initialize the output file with header
       echo "taxid,rel_abundance" > "$output_file"

        # Concatenate all CSV files in the subdirectory into a single file
        cat "$subdir"/*.csv > "$output_file.tmp"

       # Extract the top 20 most abundant bacteria and append to the output file
        tail -n +2 "$output_file.tmp" | sort -t',' -k2 -nr | head -n 20 >> "$output_file"

        # Remove temporary file
        rm "$output_file.tmp"#
   fi
done

echo "Top 20 most abundant bacteria files generated in $output_dir" 


# Navigate to the directory containing your CSV files
cd /mnt/Study2pipeline/nextflow/NanoCLUST/results/compiled_results

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


###Python section###
python3 <<END
# Python code goes her

print("This is Python code running from the shell script.")


import pandas as pd
import os

# Get a list of all CSV files in the directory
directory = '/mnt/Study2pipeline/nextflow/NanoCLUST/results/compiled_results'
csv_files = [file for file in os.listdir(directory) if file.endswith('.csv')]

# Initialize an empty DataFrame to store the result
result_df = pd.DataFrame(columns=['taxid'])

# Iterate through each file to merge data
for file in csv_files:
    df = pd.read_csv(os.path.join(directory, file))
    if 'taxid' in df.columns and 'rel_abundance' in df.columns:
        # Filter out rows with missing values in 'taxid' or 'rel_abundance' columns
        df = df.dropna(subset=['taxid', 'rel_abundance'])
        # Set 'taxid' as the index
        df.set_index('taxid', inplace=True)
        # Rename the 'rel_abundance' column to include th
df.rename(columns={'rel_abundance': file.replace('_all.csv', '')}, inplace=True) 
# Merge the dataframes on 'taxid' index
 result_df = pd.merge(result_df, df, left_index=True, right_index=True, how='outer')
# Drop the duplicate 'taxid' column
 result_df.drop(columns=['taxid'], inplace=True)

#Remove duplicate rows based on 'taxid'
 result_df = result_df[~result_df.index.duplicated(keep='first')]

#Remove the last row
 result_df = result_df.iloc[:-1]

#Save the result to a new CSV file
 result_df.to_csv('result.csv')

print("Files processed successfully:", csv_files)

END
