#' Compare two sources of April air temperature information
#' Source one: NWS website:
#'   -> http://www.arh.noaa.gov/clim/climate.php?stnid=PAOM&mon=4&yr=2015&type=obs
#' Source two: Axiom data feed
#'   -> http://www.aoos.org/2015-yukon-chinook-forecasting/

library(stringr)
library(dplyr)


nws <- read.csv('air_temp_april_axiom.csv')  


names(nws) <- c("date", "tempc")

str_sub(, 9, 10)

# Get just the dates out
nws <- nws %>% mutate(day = str_sub(date, 9, 10))

# Calcuate daily mean temperatures
nws_dailymean <- nws %>% group_by(day) %>% summarize(meantemp_c = mean(tempc))
nws_dailymean <- nws_dailymean %>% mutate(meantemp_f = meantemp_c * (9/5) + 32)

# Calcualte monthly mean
mean(nws_dailymean$meantemp_c)
mean(nws_dailymean$meantemp_f)
