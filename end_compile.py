import pandas as pd
import os

# Get a list of all CSV files in the directory
directory = '/mnt/Study_2_pipeline/Study2pipeline/nextflow/NanoCLUST/results/compiled_results'
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
        # Rename the 'rel_abundance' column to include the file name
        df.rename(columns={'rel_abundance': file.replace('_all.csv', '')}, inplace=True)
        # Merge the dataframes on 'taxid' index
        result_df = pd.merge(result_df, df, left_index=True, right_index=True, how='outer')

# Drop the duplicate 'taxid' column
result_df.drop(columns=['taxid'], inplace=True)

# Remove duplicate rows based on 'taxid'
result_df = result_df[~result_df.index.duplicated(keep='first')]

# Remove the last row
result_df = result_df.iloc[:-1]

# Save the result to a new CSV file
result_df.to_csv('result.csv')

print("Files processed successfully:", csv_files)
