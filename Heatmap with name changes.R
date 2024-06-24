library(pheatmap)

# Assuming 'my_data' is your dataframe
colnames(result) <- gsub("^X", "", colnames(result))

# Display the data to verify the column names
print(head(result))


# Replace NA values with 0
result[is.na(result)] <- 0

x <- as.matrix(result)

# Adjust margins to provide more room for legends
par(mar = c(6, 6, 6, 12))

# Create the pheatmap plot
heatmap_obj <- pheatmap(result,
                        annotation_legend = TRUE,
                        display_numbers = FALSE,
                        cluster_rows = TRUE,
                        cluster_cols = FALSE,
                        clustering_method = "ward.D",
                        clustering_distance_rows = "euclidean",
                        clustering_distance_cols = "euclidean",
                        fontsize = 4)
library("grid")

# Increase the width of the gtable column containing row names
heatmap_obj$gtable$widths[5] <- heatmap_obj$gtable$widths[5] + unit(4, "bigpts")


# Print the modified heatmap
print(heatmap_obj)
