#' hindcast.R
#' Hindcasts the April linear regression to assess predictive performance

library(ggplot2)
theme_set(theme_classic())
library(reshape2)
library(dplyr)

# Read in data
yuk <- read.csv('yukon.csv')

# Set up hindcast formulae and years

hindcast_formulae <- list("mdj" = "mdj ~ amatc", 
                          "qdj" = "qdj ~ amatc",
                          "fifdj" = "fifdj ~ amatc")
hindcast_years <- 1990:2014


# Do the hindcast by formula and year and save the result
result <- data.frame()

for (frm in hindcast_formulae) {
  for (y in hindcast_years) {
    # Establish training set
    yuk_hindcast <- subset(yuk, year < y)
    
    # Train model
    last_fit <- lm(eval(frm), data = yuk_hindcast)
    
    # Hindcast
    last_pred <- predict(last_fit, 
                         newdata = data.frame(year = y, 
                                              amatc = yuk[yuk$year == y, "amatc"]),
                         se.fit = TRUE)
    # Save result
    result <- rbind(result,
                    data.frame(formula = frm,
                               year = y,
                               observed = yuk[yuk$year == y, names(which(hindcast_formulae == frm))],
                               predicted = floor(last_pred$fit[[1]]),
                               se.fit = last_pred$se.fit))
  }
}

# Calculate residuals
result$residual <- result$observed - result$predicted

# Hindcast performance metrics
hindcast_metrics <- result %>% 
  group_by(formula) %>% 
  summarize(mape = mean(abs(residual)),
            intwidth = mean(se.fit * 4),
            propin = sum(observed > predicted - 2 * se.fit & 
                           observed < predicted + 2 * se.fit) / length(hindcast_years))

write.csv(hindcast_metrics, file = "output/hindcast_metrics.csv")


# Plotting
result_m <- melt(result[,c("formula", "year", "observed", "predicted")], id.var = c("formula", "year"))

ggplot() + 
  geom_ribbon(data = result, aes(x = year, 
                                 ymax = predicted + 2 * se.fit,
                                 ymin = predicted - 2 * se.fit),
              alpha = 0.2,
              fill = "red",
              color = "red") +
  geom_point(data = result_m, aes(year, value, colour = variable, shape = variable)) + 
  geom_line(data = result_m, aes(year, value, colour = variable, shape = variable)) + 
  scale_color_manual(values = c("black", "red")) + 
  scale_shape_manual(values = c(19, 1)) +
  facet_wrap(~ formula, ncol = 1) +
  labs(x = "Year", y = "Median Entry Timing (days  of June)")

# Save figures in PDF + PNG format
ggsave(filename = "figures/hindcast_result.pdf", width = 8, height = 8)
ggsave(filename = "figures/hindcast_result.png", width = 8, height = 8)
