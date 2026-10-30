# ==============================================================================
# Mini-Project: Statistical Analysis of E-Commerce Customer Spending Using R
# Dataset: Real Kaggle E-Commerce Customers Dataset (N = 500)
# Subject: Statistics with R | MCA 1st Semester, Chandigarh University
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

# Mode calculation helper
calc_mode <- function(x) {
  u <- unique(round(x, 1))
  u[which.max(tabulate(match(round(x, 1), u)))]
}

# --- 1. DATA IMPORT & CLEANING ---
cat("\n================================================================================\n")
cat("   1. DATA INGESTION & DATA CLEANING (REAL KAGGLE ECOMMERCE DATASET)\n")
cat("================================================================================\n")

df <- read.csv(file.path("data", "ecommerce_customers.csv"))
colnames(df) <- c(
  "Email", "Address", "Avatar", "Avg_Session_Length",
  "Time_on_App", "Time_on_Website", "Length_of_Membership", "Yearly_Amount_Spent"
)

cat(sprintf("Dataset loaded: %d Rows, %d Columns (Source: Kaggle)\n", nrow(df), ncol(df)))
cat(sprintf("Missing Values Count across dataset: %d\n", sum(is.na(df))))

# Feature engineering: Customer tiers based on spend and membership tenure
df$Spending_Tier <- factor(ifelse(df$Yearly_Amount_Spent >= 500, "High Spender", "Regular Spender"),
  levels = c("Regular Spender", "High Spender")
)
df$Membership_Tier <- factor(ifelse(df$Length_of_Membership >= 3.5, "Loyal Member", "New Member"),
  levels = c("New Member", "Loyal Member")
)

# --- 2. DESCRIPTIVE STATISTICS ---
cat("\n================================================================================\n")
cat("   2. DESCRIPTIVE STATISTICS (CENTRAL TENDENCY & DISPERSION)\n")
cat("================================================================================\n")

num_vars <- c("Avg_Session_Length", "Time_on_App", "Time_on_Website", "Length_of_Membership", "Yearly_Amount_Spent")
desc_list <- lapply(num_vars, function(v) {
  x <- df[[v]]
  data.frame(
    Variable = v, Mean = round(mean(x), 2), Median = round(median(x), 2),
    Mode = round(calc_mode(x), 2), Variance = round(var(x), 2), Std_Dev = round(sd(x), 2),
    Min = round(min(x), 2), Max = round(max(x), 2), Range = round(max(x) - min(x), 2),
    Q1 = round(quantile(x, 0.25), 2), Q3 = round(quantile(x, 0.75), 2), IQR = round(IQR(x), 2)
  )
})
desc_tbl <- do.call(rbind, desc_list)
print(desc_tbl, row.names = FALSE)

# --- 3. FREQUENCY DISTRIBUTION & CROSS-TABULATION ---
cat("\n================================================================================\n")
cat("   3. FREQUENCY DISTRIBUTION & PERCENTAGE ANALYSIS\n")
cat("================================================================================\n")

spend_freq <- table(df$Spending_Tier)
print(data.frame(
  Tier = names(spend_freq), Count = as.numeric(spend_freq),
  Percentage = round(as.numeric(prop.table(spend_freq)) * 100, 2)
))

cat("\nCross-Tabulation: Membership Tier vs. Spending Tier:\n")
cross_tab <- table(df$Membership_Tier, df$Spending_Tier)
print(cross_tab)
cat("\nRow Percentages (% within Membership Tier):\n")
print(round(prop.table(cross_tab, 1) * 100, 2))

# --- 4. DATA VISUALIZATION ---
cat("\n================================================================================\n")
cat("   4. DATA VISUALIZATION (BASE R & GGPLOT2 - 300 DPI)\n")
cat("================================================================================\n")
if (!dir.exists("plots")) dir.create("plots", recursive = TRUE)

theme_pub <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#1e3a8a", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "#475569", hjust = 0.5),
    axis.title = element_text(face = "bold", color = "#1e293b")
  )

# P1: Bar Chart
p1 <- ggplot(df, aes(x = Membership_Tier, fill = Spending_Tier)) +
  geom_bar(position = "dodge", width = 0.55, color = "black") +
  scale_fill_manual(values = c("Regular Spender" = "#94a3b8", "High Spender" = "#3b82f6")) +
  labs(title = "Kaggle E-Commerce: Spending Tier by Membership", x = "Membership Tier", y = "Count") +
  theme_pub
ggsave(file.path("plots", "01_membership_tier_bar.png"), plot = p1, width = 7.5, height = 5, dpi = 300)

# P2: Pie Chart
png(file.path("plots", "02_spending_tier_pie.png"), width = 2000, height = 1600, res = 300)
pie(spend_freq,
  labels = paste0(names(spend_freq), "\n", spend_freq, " (", round(prop.table(spend_freq) * 100, 1), "%)"),
  col = c("#cbd5e1", "#10b981"), main = "Customer Spending Tier Distribution (N = 500)", col.main = "#1e3a8a"
)
dev.off()

# P3: Histogram with Normal Fit
p3 <- ggplot(df, aes(x = Yearly_Amount_Spent)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 25, fill = "#6366f1", color = "white", alpha = 0.75) +
  stat_function(
    fun = dnorm, args = list(mean = mean(df$Yearly_Amount_Spent), sd = sd(df$Yearly_Amount_Spent)),
    color = "#dc2626", linewidth = 1.1
  ) +
  geom_vline(xintercept = mean(df$Yearly_Amount_Spent), linetype = "dashed", color = "#059669", linewidth = 1) +
  labs(
    title = "Distribution of Yearly Amount Spent ($)", subtitle = "Histogram with Normal Density Curve Overlay",
    x = "Yearly Amount Spent ($)", y = "Density"
  ) +
  theme_pub
ggsave(file.path("plots", "03_yearly_spending_histogram.png"), plot = p3, width = 8, height = 5, dpi = 300)

# P4: Boxplot
p4 <- ggplot(df, aes(x = Membership_Tier, y = Yearly_Amount_Spent, fill = Membership_Tier)) +
  geom_boxplot(alpha = 0.7, width = 0.45) +
  geom_jitter(width = 0.15, alpha = 0.25, size = 1.5) +
  scale_fill_manual(values = c("New Member" = "#f87171", "Loyal Member" = "#34d399")) +
  labs(title = "Yearly Spending Comparison Across Membership Tiers", x = "Membership Tier", y = "Yearly Spend ($)") +
  theme_pub +
  theme(legend.position = "none")
ggsave(file.path("plots", "04_spending_by_tier_boxplot.png"), plot = p4, width = 7.5, height = 5, dpi = 300)

# P5: Scatter Plot with OLS Fit
p5 <- ggplot(df, aes(x = Time_on_App, y = Yearly_Amount_Spent)) +
  geom_point(aes(color = Spending_Tier), alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", color = "#1e3a8a", fill = "#93c5fd", linewidth = 1.1) +
  scale_color_manual(values = c("Regular Spender" = "#64748b", "High Spender" = "#059669")) +
  labs(
    title = "Time on App vs. Yearly Amount Spent", subtitle = "Fitted OLS Linear Trend with 95% Confidence Band",
    x = "Time on App (Minutes/Day)", y = "Yearly Amount Spent ($)"
  ) +
  theme_pub
ggsave(file.path("plots", "05_app_time_vs_spending_scatter.png"), plot = p5, width = 8, height = 5, dpi = 300)

# P6: Correlation Heatmap
c_mat <- cor(df[num_vars])
c_df <- as.data.frame(as.table(c_mat))
p6 <- ggplot(c_df, aes(x = Var1, y = Var2, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", Freq)), fontface = "bold", size = 3.8) +
  scale_fill_gradient2(low = "#ef4444", mid = "#f8fafc", high = "#2563eb", midpoint = 0, limit = c(-1, 1), name = "Pearson r") +
  labs(title = "Pearson Correlation Heatmap (Kaggle Dataset)", x = "", y = "") +
  theme_pub +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))
ggsave(file.path("plots", "06_correlation_heatmap.png"), plot = p6, width = 8, height = 6, dpi = 300)

cat("Visualizations generated and saved to plots/ directory successfully.\n")

# --- 5. COVARIANCE & CORRELATION ANALYSIS ---
cat("\n================================================================================\n")
cat("   5. COVARIANCE & CORRELATION ANALYSIS\n")
cat("================================================================================\n")

cat("Sample Covariance Matrix:\n")
print(round(cov(df[num_vars]), 2))
cat("\nPearson Correlation Matrix:\n")
print(round(cor(df[num_vars]), 3))

# Hypothesis test for correlation
cor_test_res <- cor.test(df$Time_on_App, df$Yearly_Amount_Spent)
cat(sprintf(
  "\nPearson Test (Time on App vs. Yearly Spend): r = %.4f, t = %.2f, p-value = %e (Significant)\n",
  cor_test_res$estimate, cor_test_res$statistic, cor_test_res$p.value
))

# --- 6. PROBABILITY DISTRIBUTIONS ---
cat("\n================================================================================\n")
cat("   6. PROBABILITY DISTRIBUTIONS (EMPIRICAL, BINOMIAL & NORMAL)\n")
cat("================================================================================\n")

p_high <- mean(df$Spending_Tier == "High Spender")
cat(sprintf("Empirical Probability P(High Spender >= $500): %.4f (%.2f%%)\n", p_high, p_high * 100))

# Conditional: P(High Spender | Loyal Member)
loyal_df <- subset(df, Membership_Tier == "Loyal Member")
p_cond <- mean(loyal_df$Spending_Tier == "High Spender")
cat(sprintf("Conditional Probability P(High Spender | Loyal Member >= 3.5 yrs): %.4f (%.2f%%)\n", p_cond, p_cond * 100))

# Binomial Distribution: Sample of n = 10 customers
cat(sprintf("\nBinomial B(n = 10, p = %.2f) -> P(Exactly 5 High Spenders): %.4f\n", p_high, dbinom(5, 10, p_high)))
cat(sprintf("Binomial B(n = 10, p = %.2f) -> P(At least 6 High Spenders): %.4f\n", p_high, 1 - pbinom(5, 10, p_high)))

# Normal Distribution
mu_y <- mean(df$Yearly_Amount_Spent)
sd_y <- sd(df$Yearly_Amount_Spent)
cat(sprintf("\nNormal Model: Y ~ N(mu = $%.2f, sigma = $%.2f)\n", mu_y, sd_y))
cat(sprintf("Theoretical P(Spend >= $600): %.4f (Z = %.2f)\n", 1 - pnorm(600, mu_y, sd_y), (600 - mu_y) / sd_y))
cat(sprintf("Theoretical 90th Percentile Cutoff: $%.2f\n", qnorm(0.90, mu_y, sd_y)))

# --- 7. HYPOTHESIS TESTING (t-TESTS) ---
cat("\n================================================================================\n")
cat("   7. INFERENTIAL HYPOTHESIS TESTING (t-TESTS)\n")
cat("================================================================================\n")

# One-sample t-test: H0: mu = 500 vs H1: mu != 500
t1 <- t.test(df$Yearly_Amount_Spent, mu = 500)
cat(sprintf(
  "One-Sample t-Test (Benchmark $500): t = %.4f, df = %d, p-value = %.4f\n",
  t1$statistic, t1$parameter, t1$p.value
))
cat(sprintf(
  "Conclusion: %s (Mean = $%.2f, 95%% CI: [$%.2f, $%.2f])\n",
  ifelse(t1$p.value < 0.05, "Reject H0 (Differs from $500)", "Fail to Reject H0 (Consistent with $500)"),
  t1$estimate, t1$conf.int[1], t1$conf.int[2]
))

# Two-sample t-test: Spend comparison across Membership Tiers
f_var <- var.test(Yearly_Amount_Spent ~ Membership_Tier, data = df)
t2 <- t.test(Yearly_Amount_Spent ~ Membership_Tier, data = df, var.equal = (f_var$p.value > 0.05))
cat(sprintf(
  "\nTwo-Sample t-Test (Membership Tiers): t = %.4f, df = %d, p-value = %e\n",
  t2$statistic, t2$parameter, t2$p.value
))
cat(sprintf(
  "Loyal Mean = $%.2f, New Member Mean = $%.2f (Significant difference: p < 0.001)\n",
  t2$estimate[2], t2$estimate[1]
))

# --- 8. SIMPLE LINEAR REGRESSION & DIAGNOSTICS ---
cat("\n================================================================================\n")
cat("   8. SIMPLE LINEAR REGRESSION & RESIDUAL DIAGNOSTICS\n")
cat("================================================================================\n")

reg <- lm(Yearly_Amount_Spent ~ Time_on_App, data = df)
reg_sum <- summary(reg)
print(reg_sum)

cat(sprintf(
  "\nRegression Equation: Yearly_Amount_Spent = %.2f + (%.2f * Time_on_App)\n",
  coef(reg)[1], coef(reg)[2]
))
cat(sprintf("Slope Interpretation: Every extra minute on the app increases annual spend by $%.2f\n", coef(reg)[2]))
cat(sprintf(
  "R-squared: %.4f (%.2f%% of variance explained) | F = %.2f (p = %e)\n",
  reg_sum$r.squared, reg_sum$r.squared * 100, reg_sum$fstatistic[1],
  pf(reg_sum$fstatistic[1], reg_sum$fstatistic[2], reg_sum$fstatistic[3], lower.tail = FALSE)
))

# Predictions for 10, 12, 14, 16 mins
pred_df <- data.frame(Time_on_App = c(10, 12, 14, 16))
preds <- predict(reg, newdata = pred_df, interval = "confidence")
cat("\nPredicted Yearly Spend Scenarios:\n")
print(cbind(pred_df, round(preds, 2)))

# Shapiro-Wilk Residual Normality Test
sw <- shapiro.test(residuals(reg))
cat(sprintf(
  "\nResidual Normality (Shapiro-Wilk): W = %.4f, p-value = %.4f (%s)\n",
  sw$statistic, sw$p.value, ifelse(sw$p.value > 0.05, "Normality Met", "Deviates from Normal")
))

# 4-Panel Diagnostic Plot
png(file.path("plots", "07_regression_diagnostic_plots.png"), width = 2400, height = 2400, res = 300)
par(mfrow = c(2, 2))
plot(reg, col = "#2563eb", pch = 19)
dev.off()
