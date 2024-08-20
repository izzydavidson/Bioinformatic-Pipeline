library(ggplot2)
library(tidyr)
library(dplyr)

# Read the CSV file
result <- read_csv("/Users/izzydavidson/Desktop/result1.csv", col_names = TRUE)

# Replace NA values with 0
result[is.na(result)] <- 0

print(result)

# Assuming 'result' is your dataframe
data_long <- result %>%
  pivot_longer(
    cols = -taxid,
    names_to = "Sample_Primer",
    values_to = "Abundance"
  ) %>%
  separate(Sample_Primer, into = c("Sample", "Primer"), sep = " ")

# View the reshaped data
print(data_long)

data_long <- data_long %>%
  mutate(Sample_Primer = paste(Sample, Primer, sep = "_"))
# View the reshaped data
print(data_long)

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

# Make Bar Chart
ggplot(data_long, aes(x = Primer, y = Abundance, fill = taxid)) +
  geom_bar(stat = "identity", width = 0.6) +
  labs(title = "Microbial Abundance by Sample and Primer",
       x = "Primer", y = "Abundance") +
  facet_grid(~ Sample, scales = "free_x", space = "free_x", switch = "x") +  # Switch facets to the bottom
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",  # Position the legend at the bottom
        legend.text = element_text(size = 4),  # Make legend text smaller
        legend.title = element_text(size = 7),  # Make legend title smaller
        legend.key.size = unit(0.2, "cm"),  # Reduce the size of legend keys
        legend.key.width = unit(0.3, "cm"),  # Reduce the width of legend keys
        legend.spacing.x = unit(0.1, "cm"),  # Reduce horizontal spacing between legend items
        plot.margin = margin(t = 10, r = 10, b = 10, l = 10),  # Adjust plot margins
        strip.background = element_rect(fill = "white", color = "white"),  # Blend group panel with chart background
        strip.placement = "outside",  # Place strip outside of the chart
        panel.spacing = unit(-0.01, "cm")) +  # Remove the gap between panels
  scale_fill_manual(values = pastel_colors)  # Set custom fill colors
