# April forecast
# Forecast 15/25/50% points using AMATC only

library(ggplot2)
theme_set(theme_bw())


yuk <- read.csv('data/yukon.csv')

ggplot(yuk, aes(year, amatc)) + 
  geom_point(size = 2) +
  geom_boxplot(aes(x = 2015), width = 2, outlier.colour = "white") +
  annotate(geom = "point",
           x = yuk[nrow(yuk),"year"],
           y = yuk[nrow(yuk),"amatc"],
           color = "red",
           size = 2) +
  scale_x_continuous(breaks = c(1961, 1970, 1980, 1990, 2000, 2015)) +
  labs(x = "Year", y = "AMATC")

ggsave(filename = "figures/historical_amatc.png", width = 6, height = 4)
ggsave(filename = "figures/historical_amatc.pdf", width = 6, height = 4)

# MDJ
fit_mdj_full <- lm(mdj ~ amatc, data = subset(yuk, year < 2015))
mdj_prd <- predict(fit_mdj_full, newdata = data.frame(year = 2015, amatc = yuk[nrow(yuk), "amatc"]))

# QDJ
fit_qdj_full <- lm(qdj ~ amatc, data = subset(yuk, year < 2015))
qdj_prd <- predict(fit_qdj_full, newdata = data.frame(year = 2015, amatc = yuk[nrow(yuk), "amatc"]))

# FIFDJ
fit_fifdj_full <- lm(fifdj ~ amatc, data = subset(yuk, year < 2015))
fifdj_prd <- predict(fit_fifdj_full, newdata = data.frame(year = 2015, amatc = yuk[nrow(yuk), "amatc"]))

prd_df <- data.frame(percentile = ordered(x = c("FIFDJ", "QDJ", "MDJ")),
                     proportion = c(0.15, 0.25, 0.50),
                     day = c(
                       floor(fifdj_prd),
                       floor(qdj_prd),
                       floor(mdj_prd)))

# Fit a 2-param logistic curve via minimizing SSQ
logifn <- function(x, mu, s) 1 / (1 + exp(-(( x - mu) / s)))
logifn_rss <- function(par, x) sum((c(0.15, 0.25, 0.50) - logifn(x, par[1], par[2]))^2)


optim_result <- optim(par = c(15, 5),
                      fn  = logifn_rss,
                      x   = floor(c(fifdj_prd, qdj_prd, mdj_prd)))

xrange <- c(-10, 50)
xseq <- seq(xrange[1], xrange[2])

cumulative_prediction <- data.frame(x = xseq, y = logifn(xseq, mu = optim_result$par[1], s = optim_result$par[2]))

ggplot() + 
  geom_point(data = prd_df, aes(day, proportion), color = "red") + 
  geom_line(data = cumulative_prediction, aes(x, y)) +
  scale_x_continuous(breaks = c(1, 15, 31, 45), labels = c("June 1", "June 15", "July 1", "July 15")) +
  scale_y_continuous(limits=c(0,1)) + 
  annotate(geom = "text", 
           x = prd_df$day, 
           y = prd_df$proportion,
           label = paste("June", prd_df$day),
           angle = 90,
           hjust = -.5,
           size = 2.5) +
  annotate(geom = "text", 
           x = prd_df$day, 
           y = 0,
           label = paste0(prd_df$proportion * 100, "%"),
           vjust = 0,
           hjust = -0.1,
           size = 2.5) +
  annotate(geom = "segment",
           x = prd_df$day,
           xend = prd_df$day,
           y = 0,
           yend = prd_df$proportion 
           ) +
  labs(x = "Date", y = "Cumulative Proportion of CPUE")

ggsave("figures/forecast.pdf", width = 8, height = 4)
ggsave("figures/forecast.png", width = 8, height = 4)
