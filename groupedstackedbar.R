#Reading and Parsing Data: Ensured the data reads properly and the Patient and Primer information are 
#correctly extracted from the column names.
#Data Transformation: Adjusted data frame transformations to create a PatientPrimer column and later 
#separated this into Patient and Primer.
#Plot Customization: Used interaction(Patient, Primer) for the x-axis to group the data by both patient 
#and primer.

library(readr)
library(tidyr)
library(ggplot2)
library(dplyr)

# Read the CSV file
result <- read_csv("Desktop/Masters/Bioinformatics_results/basecaller/specific_with_parameters/result.csv", col_names = TRUE)

# Replace NA values with 0
result[is.na(result)] <- 0

# Transpose the data
data_transposed <- t(result)

# Convert to data frame
df <- as.data.frame(data_transposed)

# Rename columns
colnames(df) <- df[1,]

# Remove the first row (it contains the previous column names)
df <- df[-1,]

# Reset row names
row.names(df) <- NULL

# Extract patient and primer information from the top row of result
patient_primer <- colnames(result)[-1]
patient_primer <- gsub("\\.csv", "", patient_primer)
patient_primer_split <- strsplit(patient_primer, " ")
patients <- sapply(patient_primer_split, `[`, 1)
primers <- sapply(patient_primer_split, `[`, 2)
patient_primer_combined <- paste(patients, primers, sep = " ")

# Create result_long with patient, primer, taxid, and abundance columns
result_long <- data.frame(
  PatientPrimer = rep(patient_primer_combined, each = nrow(result) - 1),
  taxid = as.character(unlist(result[-1, 1])),
  abundance = as.numeric(unlist(result[-1, -1]))
)

# Calculate the sum of abundances for each patient and primer
patient_primer_sum <- aggregate(abundance ~ PatientPrimer, data = result_long, FUN = sum)

# Merge the sum of abundances back into result_long
result_long <- merge(result_long, patient_primer_sum, by = "PatientPrimer", suffixes = c("", "_sum"))

# Calculate the fraction of reads for each taxonomic group
result_long$fraction <- result_long$abundance / result_long$abundance_sum

# Separate patient and primer information for plotting
result_long <- result_long %>%
  separate(PatientPrimer, into = c("Patient", "Primer"), sep = " ")

# Define colors
pastel_colors <- c("#00FF7F", "#FFB6C1", "#FFA07A", "#87CEEB", "#66CDAA", 
                   "#B0C4DE", "#FFA500", "#778899", "#E0FFFF", "#FF99FF",
                   "#F0FFFF", "#AFEEEE", "#9932CC", "#ADD8E6", "#98FB98", 
                   "#FF00FF", "#90EE90", "#BA55D3", "#2E8B57", "#7B68EE", "#8FBC8F", 
                   "#FF1493", "#10DD7F", "#FF0000", "#7FFFD4", "#1E90FF", 
                   "#66CDAA", "#6495ED", "#7B68EE", "#9370DB", "#800080", 
                   "#20B2AA", "#DA70D6", "#3CB371", "#FFC0CB", "#FF7F50", 
                   "#CD5C5C", "#E9967A", "#F0E68C", "#E9967A", "#FFD700", 
                   "#32CD32", "#DAA520", "#FF69B4", "#00BFFF", "#98FB98", 
                   "#FF6347", "#FFD999", "#DDD520", "#FF99D9", "#4682B4", 
                   "#000080", "#FF4500", "#8A2BE2", "#FFD700", "#00FFFF", 
                   "#FF69B4", "#8B4513", "#556B2F", "#FF8C00", "#6A5ACD", 
                   "#20B2AA", "#B22222", "#2E8B57")

# Generate plot with updated color palette
ggplot(result_long, aes(x = interaction(Patient, Primer), y = fraction, fill = taxid)) +
  geom_bar(stat = "identity") +
  labs(title = "Stacked Bar Graph of Taxid Abundance",
       x = "Patient and Primer", y = "Fraction of Reads") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.text = element_text(size = 6),  # Adjust legend text size
        legend.title = element_text(size = 8),  # Adjust legend title size
        legend.key.size = unit(0.3, "cm"),  # Adjust legend key size
        legend.key.width = unit(0.5, "cm"),  # Adjust legend key width
        axis.text = element_text(size = 8),  # Adjust axis text size
        axis.title = element_text(size = 10),  # Adjust axis title size
        plot.title = element_text(size = 12)) +  # Adjust plot title size
  scale_fill_manual(values = pastel_colors)  # Set custom fill colors
