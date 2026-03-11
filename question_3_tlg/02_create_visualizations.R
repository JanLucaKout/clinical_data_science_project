# ==============================================================================
# Script: 02_create_visualizations.R
# Objective: Generate Figures (Plots)
# Required Packages: pharmaverseraw, dplyr, ggplot2

# ==============================================================================
# Libraries
library(pharmaverseadam)
library(dplyr)
library(ggplot2)

# ==============================================================================
# Read in data
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# ==============================================================================
# Pre-processing Figure 1
plot_data <- adae |>
  filter(TRTEMFL == "Y") |>
  mutate(
    # Ensure Treatment Groups are in the correct order for the X-axis
    ACTARM = factor(ACTARM, levels = c("Placebo", "Xanomeline High Dose", "Xanomeline Low Dose")),
    # Ensure Severity is ordered for the stacking
    AESEV = factor(AESEV, levels = c("MILD", "MODERATE", "SEVERE"))
  )

# ==============================================================================
# Figure 1: AE Severity Distribution by Treatment
fig1 <- ggplot(plot_data, aes(x = ACTARM, fill = AESEV)) +
  # Using position = "stack" to create the stacked effect
  geom_bar(position = "stack", color = "white", linewidth = 0.2) +
  theme_grey(base_size = 10) +
  
  scale_fill_brewer(palette = "Set2") + 
  labs(
    title = "",
    subtitle = "AR severity distribution by treatment",
    x = "Treatment Arm",
    y = "Count of AEs",
    fill = "Severity/Intensity"
  ) +
  theme(
    legend.position = "right",
    panel.grid.major.x = element_blank() # Clean up the vertical lines
  )

# ==============================================================================
# Pre-processing Figure 2: Overall Incidence and 95% CI for the Top 10 AEs
total_n <- n_distinct(adsl$USUBJID)

plot_data_fig2 <- adae |>
  filter(TRTEMFL == "Y") |>
  group_by(AETERM) |>
  summarise(N_EVENT = n_distinct(USUBJID), .groups = "drop") |>
  mutate(
    RATE = N_EVENT / total_n,
    # Standard Error for Proportion
    SE = sqrt((RATE * (1 - RATE)) / total_n),
    # 95% Confidence Interval (Normal Approximation)
    LCL = pmax(0, RATE - 1.96 * SE),
    UCL = pmin(1, RATE + 1.96 * SE)
  ) |>
  # Sort by rate and take the top 10
  slice_max(order_by = RATE, n = 10)

# ==============================================================================
# Figure 2: Top 10 Most Frequent Adverse Events
fig2 <- ggplot(plot_data_fig2, aes(x = RATE, y = reorder(AETERM, RATE))) +
  geom_point(size = 3, color = "black")+
  geom_errorbarh(aes(xmin = LCL, xmax = UCL), 
                 height = 0.2, 
                 color = "black", 
                 linewidth = 0.8) +
  
  theme_grey(base_size = 12) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), 
                     expand = expansion(mult = c(0, .15)))
  
  labs(
    title = "Top 10 Most Frequent Adverse Events",
    subtitle = paste0("n = ", total_n, " subjects; 95% Clopper-Pearson CIs"),
    x = "Percentage of Patients (%)",
    y = ""
  ) +
  theme(
    panel.grid.major.y = element_line(color = "white"),
    plot.title = element_text(face = "bold")
  )
  
# ==============================================================================
# Save Deliverables
  
ggsave("question_3_tlg/figure_1_ae_severity.png", plot = fig1, width = 8, height = 6, dpi = 300)
ggsave("question_3_tlg/figure_2_ae_soc_distribution.png", plot = fig2, width = 10, height = 7, dpi = 300)

# ==============================================================================
# Completion and Logging
log_file <- "question_3_tlg/02_create_visualizations_log.txt"
sink(log_file)
cat("Execution Log: 02_create_visualizations.R\n")
cat("DateTime: ", as.character(Sys.time()), "\n\n")
cat("Summary of Plot Data:\n")
print(table(plot_data$ACTARM, plot_data$AESEV))
cat("\nFigures 1 and 2 successfully saved in 'question_3_tlg/'.\n")
sink()

print("Figures successfully generated and logged!")
# ==============================================================================