library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

out="./Plots/"
# read in all data
data <- read.table("All_Time_At_Depot.txt", sep = "\t")
data$V1 <- as.POSIXct(dmy_hms(data$V1))
data$V2 <- as.POSIXct(dmy_hms(data$V2))
data$duration <- data$V2-data$V1
data <- filter(data, V2>V1)
data <- unite(data, "TruckDriver", V12:V13, remove = TRUE)
data$date <- as.POSIXct(cut(data$V1, breaks = "1 day"))
data <- arrange(data, V1)

# here we make a plot using the linearange to show the spans of time for each truck:driver spent in depot
g <- ggplot(data, aes(x = date, y = TruckDriver, colour = TruckDriver, ))+
    scale_x_datetime(breaks = date_breaks("2 day"), labels = date_format("%d-%B"))+
    geom_linerange(aes(xmin = V1, xmax = V2), size = 2)+
    theme_bw()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1), legend.position = "none")
ggsave(paste0(out, "Visual_Summary_Time_At_Depot.png"), plot = g, height = 6, width = 20)
