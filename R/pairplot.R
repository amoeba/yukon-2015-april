# pairplot.R
# Paired scatterplot for MDJ/QDJ/FIFDJ ~ AMATC


yuk <- read.csv("./data/yukon.csv")
png(filename = "./figures/pairplot.png", width = 600, height = 400)
pairs(yuk[,c("mdj", "qdj", "fifdj", "amatc")])
dev.off()
