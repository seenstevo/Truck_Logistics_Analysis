library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

setwd("/home/sean/Documentos/NewEnt_Logistics/History_Files/Formatted_History_Files")
out="/home/sean/Documentos/NewEnt_Logistics/History_Files/Plots/"
# read in all data
data <- read.table("All_Time_At_Net.txt", sep = "\t")
data$V1 <- as.POSIXct(dmy_hms(data$V1))
data$V2 <- as.POSIXct(dmy_hms(data$V2))
data$duration <- data$V2-data$V1
data <- filter(data, V2>V1)
data <- unite(data, "TruckDriver", V12:V13, remove = TRUE)
data$date <- as.POSIXct(cut(data$V1, breaks = "1 day"))
data <- arrange(data, V1)

g <- ggplot(data, aes(x = date, y = TruckDriver, colour = TruckDriver, ))+
    scale_x_datetime(breaks = date_breaks("2 day"), labels = date_format("%d-%B"))+
    geom_linerange(aes(xmin = V1, xmax = V2), size = 2)+
    theme_bw()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1), legend.position = "none")
ggsave(paste0(out, "Visual_Summary_Time_Net_Logistics.png"), plot = g, height = 6, width = 20)

##### all below is to ignore and delete
# need some way to cut ranges that overflow the months into smaller chunks

time.at.Net <- data %>% 
    select(V1, V2, TruckDriver) %>% 
    mutate(month = cut(V1, breaks = "30 min"),
           time.span.hours = V2 - V1) %>% 
    select(TruckDriver, month, time.span.hours) %>% 
    filter(time.span.hours > 5000) # remove periods of ~1 hour or less

time.at.Net$time.span.hours <- as.numeric(time.at.Net$time.span.hours)
time.at.Net$time.span.hours <- time.at.Net$time.span.hours/60/60

total.by.month <- time.at.Net %>% 
    group_by(month) %>% 
    summarise(total = (sum(time.span.hours))) %>% 
    ungroup()

g <- ggplot(total.by.month, aes(x = month, y = total))+
    geom_bar(stat = "identity", alpha = 0.8)+
    theme_bw()+
    labs(y = "Total Hours", x = "Month (Oct-April)")
ggsave(paste0(out, "Total_Time_Net_By_Month.png"), plot = g, height = 4, width = 5)

g <- ggplot(time.at.Net, aes(x = time.span.hours))+
    geom_boxplot(varwidth = TRUE)+
    facet_wrap(~as.Date(month), ncol = 2)+
    theme_bw()+
    xlim(0,200)
ggsave(paste0(out, "Distribution_Periods_Net_By_Month.png"), plot = g, height = 8, width = 10)

g <- ggplot(time.at.Net, aes(x = time.span.hours))+
    geom_boxplot(varwidth = TRUE)+
    facet_wrap(~TruckDriver)+
    theme_bw()+
    xlim(0,500)
ggsave(paste0(out, "Each_TruckDriver_Period_Net_Distribution.png"), plot = g, height = 5, width = 10)

total.by.truckdriver <- time.at.Net %>% 
    group_by(TruckDriver) %>% 
    summarise(total = sum(time.span.hours)) %>% 
    ungroup()

g <- ggplot(total.by.truckdriver, aes(x = TruckDriver, y = total))+
    geom_bar(stat = "identity", alpha = 0.8)+
    theme_bw()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    labs(y = "Percentage Total Hours (Oct-April)", x = "TruckDriver")+
    facet_wrap(~as.Date(month), nrow = 1)
ggsave(paste0(out, "Percentage_Total_Hours_Spent_at_Net.png"), plot = g, height = 6, width = 20)
