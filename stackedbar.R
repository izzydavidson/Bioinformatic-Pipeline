library(readr)
library(tidyr)
library(ggplot2)

# Read the CSV file
result <- read_csv("Desktop/Masters /Bioinformatics results/basecaller/specific with parameters/result.csv", col_names = TRUE)

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

# Extract Barcode numbers from the top row of result
Barcode <- gsub("\\.csv", "", colnames(result)[-1])
Barcode <- rep(Barcode, each = nrow(result) - 1)

# Create result_long with Barcode, taxid, and abundance columns
result_long <- data.frame(
  Barcode = Barcode,
  taxid = as.character(unlist(result[-1, 1])),
  abundance = as.numeric(unlist(result[-1, -1]))
)


# Calculate the sum of abundances for each barcode
barcode_sum <- aggregate(abundance ~ Barcode, data = result_long, FUN = sum)

# Merge the sum of abundances back into result_long
result_long <- merge(result_long, barcode_sum, by = "Barcode", suffixes = c("", "_sum"))

# Calculate the fraction of reads for each taxonomic group
result_long$fraction <- result_long$abundance / result_long$abundance_sum


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
ggplot(result_long, aes(x = Barcode, y = fraction, fill = taxid)) +
  geom_bar(stat = "identity") +
  labs(title = "Stacked Bar Graph of Taxid Abundance",
       x = "Barcode", y = "Fraction of Reads") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.text = element_text(size = 3.25),  # Adjust legend text size
        legend.title = element_text(size = 5),  # Adjust legend title size
        legend.key.size = unit(0.15, "cm"),  # Adjust legend key size
        legend.key.width = unit(0.35, "cm"),  # Adjust legend key width
        axis.text = element_text(size = 5),  # Adjust axis text size
        axis.title = element_text(size = 8),  # Adjust axis title size
        plot.title = element_text(size = 8)) +  # Adjust plot title size
  scale_fill_manual(values = pastel_colors)  # Set custom fill colors

