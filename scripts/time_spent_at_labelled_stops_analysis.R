library(tidyverse)
library(ggplot2)
library(viridis)
library(stringr)
library(lubridate)

# This script will focus on the time spent at labeled geozones (col 8)
# 

####################################################################################
# data input formatting and preparation
setwd("/home/sean/Documentos/NewEnt_Logistics/History_Files/Formatted_History_Files/")
out="/home/sean/Documentos/NewEnt_Logistics/History_Files/Plots/"
# read in all data
data <- read.table("All_Merged.txt", sep = "\t")
# get date time formatted
data$V2 <- dmy_hms(data$V2)
# select columns
data <- select(data, V2, V8, V10, V11, V14, V15)
# join truck driver
data <- unite(data, "TruckDriver", V10:V11, remove = TRUE)
# rename columns
data <- rename(data, datetime = V2, Stop = V8, TripNum = V14, BeitBDirection = V15)
# remove all rows that don't have the col 8 geozone label
data <- filter(data, Stop != "")
####################################################################################
# using groupby and summarise to get total time at each stop for each trip
# important step here is using the cumsum which groups together continuous runs of each Stop location
# this prevents non-continuous Stops from being grouped
summary.td.stops <- data %>% 
    mutate(month = lubridate::floor_date(datetime, "month")) %>% 
    group_by(TripNum, TruckDriver, Stop, stopgroup = cumsum(c(1, diff(as.numeric(Stop)) != 0)), BeitBDirection) %>% 
    summarise(time.spent = max(datetime) - min(datetime), 
              across(matches("month"), unique))
# convert the seconds into minutes
summary.td.stops$time.spent <- as.numeric(summary.td.stops$time.spent)
summary.td.stops$time.spent <- summary.td.stops$time.spent/60
summary.td.stops$time.spent <- as.integer(summary.td.stops$time.spent)
####################################################################################
##### Summary of main stops
# Summary by month
summary.total.time.stop.month <- summary.td.stops %>% 
    unite("StopBB", c(Stop, BeitBDirection), remove = TRUE, sep = "") %>% 
    group_by(StopBB, month) %>% 
    summarise(total.time.month = sum(time.spent/60)) %>%
    filter(total.time.month > 100, StopBB != "Net Logistics Joburg") %>% 
    ungroup()

g <- ggplot(summary.total.time.stop.month, aes(x = reorder(StopBB, desc(total.time.month)), y = total.time.month))+
    geom_bar(stat = "identity")+
    labs(x = "GeoLocation", y = "Total Time (hrs)")+
    ggtitle("Time Spent In GeoLocation Per Month (Oct'21-April'22)")+
    facet_wrap(~as.Date(month))+
    theme_bw()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))
ggsave(paste0(out, "Time_Spent_In_Locations_By_Month.png"), plot = g, height = 8, width = 10)

# Summary by whole time period
summary.total.time.stop <- summary.td.stops %>% 
    unite("StopBB", c(Stop, BeitBDirection), remove = TRUE, sep = "") %>% 
    group_by(StopBB) %>% 
    summarise(total.time.stop = sum(time.spent/60)) %>% 
    filter(total.time.stop > 200, StopBB != "Net Logistics Joburg") %>% 
    ungroup()

g <- ggplot(summary.total.time.stop, aes(x = reorder(StopBB, desc(total.time.stop)), y = total.time.stop/24))+
    geom_bar(stat = "identity")+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    labs(x = "GeoLocation", y = "Total Time (days)")+
    ggtitle("Time Spent In GeoLocation Across Whole Period (Oct'21-April'22)")
ggsave(paste0(out, "Time_Spent_In_Locations_Whole_Time_Period.png"), plot = g, height = 4, width = 8)
####################################################################################
##### Now analysis of specific aspects of trip
# 1) Beit Bridge crossing

beitbridge.sumamry <- summary.td.stops %>% 
    filter(Stop %in% c("Beit Bridge Customs", "Weighbridge in", "New Condep", 
                       "VID ", "WTT Beitbridge", "Petrotrade fuel station"),
           BeitBDirection != "")
# want to add fill for load complexity
g <- ggplot(beitbridge.sumamry, aes(x = time.spent/60))+
    geom_histogram(bins = 30)+
    facet_grid(BeitBDirection ~ Stop)+
    xlab("Time Spent in GeoLocation (hours)")+
    ggtitle("Beitbridge Border Crossing Summary")+
    xlim(0,30)+
    ylim(0,90)+
    theme_bw()
ggsave(paste0(out, "Time_Spent_In_BeitBridge_Locations_Whole_Time_Period.png"), plot = g, height = 4, width = 10)

# 2) Groblersbrug - Border

gburg.sumamry <- summary.td.stops %>% 
    filter(Stop %in% c("Groblersbrug - Border"))
# want to add fill for load complexity
g <- ggplot(gburg.sumamry, aes(x = time.spent/60))+
    geom_histogram(bins = 20)+
    xlab("Time Spent at Groblersbrug (hours)")+
    ggtitle("Groblersbrug Border Crossing Summary")+
    theme_bw()
ggsave(paste0(out, "Time_Spent_At_Groblersbrug_Whole_Time_Period.png"), plot = g, height = 3, width = 4)

# 3) Kazungula Border

kazungula.sumamry <- summary.td.stops %>% 
    filter(Stop %in% c("Kazungula Border"))
# want to add fill for load complexity
g <- ggplot(kazungula.sumamry, aes(x = time.spent/60))+
    geom_histogram(bins = 20)+
    xlab("Time Spent at Kazungula (hours)")+
    ggtitle("Kazungula Border Crossing Summary")+
    theme_bw()
ggsave(paste0(out, "Time_Spent_At_Kazungula_Whole_Time_Period.png"), plot = g, height = 3, width = 4)
####################################################################################
##### Now looking at each drivers distribution at stops with longest times
# 4) TruckDriver Time spent at Colbro Trasnport

colbro <- summary.td.stops %>% 
    filter(Stop %in% c("Colbro Transport")) %>% 
    group_by(TruckDriver, TripNum) %>% 
    summarise(total.time.stop = sum(time.spent/60)) %>% 
    ungroup()
 
g <- ggplot(colbro, aes(x = TruckDriver, y = total.time.stop))+
    geom_boxplot()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    geom_hline(yintercept = median(colbro$total.time.stop), col = "red")
ggsave(paste0(out, "Each_Driver_Time_Spent_At_Colbro.png"), plot = g, height = 6, width = 4)

# 5) TruckDriver Time spent at WTT Beitbridge

wtt <- summary.td.stops %>% 
    filter(Stop %in% c("WTT Beitbridge")) %>% 
    group_by(TruckDriver, TripNum) %>% 
    summarise(total.time.stop = sum(time.spent/60)) %>% 
    ungroup()

g <- ggplot(wtt, aes(x = TruckDriver, y = total.time.stop))+
    geom_boxplot()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    geom_hline(yintercept = median(wtt$total.time.stop), col = "red")
ggsave(paste0(out, "Each_Driver_Time_Spent_At_WTT_Beitbridge.png"), plot = g, height = 6, width = 4)

# 6) TruckDriver Time spent at SHELL PARKING

shell <- summary.td.stops %>% 
    filter(Stop %in% c("SHELL PARKING ")) %>% 
    group_by(TruckDriver, TripNum) %>% 
    summarise(total.time.stop = sum(time.spent/60)) %>% 
    ungroup()

g <- ggplot(shell, aes(x = TruckDriver, y = total.time.stop))+
    geom_boxplot()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    geom_hline(yintercept = median(shell$total.time.stop), col = "red")
ggsave(paste0(out, "Each_Driver_Time_Spent_At_Shell_Parking.png"), plot = g, height = 6, width = 4)

# 6) TruckDriver Time spent at Kazungula Border

kazungula <- summary.td.stops %>% 
    filter(Stop %in% c("Kazungula Border")) %>% 
    group_by(TruckDriver, TripNum) %>% 
    summarise(total.time.stop = sum(time.spent/60)) %>% 
    ungroup()

g <- ggplot(kazungula, aes(x = TruckDriver, y = total.time.stop))+
    geom_boxplot()+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
    geom_hline(yintercept = median(kazungula$total.time.stop), col = "red")
ggsave(paste0(out, "Each_Driver_Time_Spent_At_Kazungula.png"), plot = g, height = 6, width = 4)
