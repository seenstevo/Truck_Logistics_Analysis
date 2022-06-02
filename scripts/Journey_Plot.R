library(tidyverse)
library(ggplot2)
library(viridis)
library(stringr)
library(lubridate)

out="./Plots/route_plots/"
files <- list.files(path="./Formatted_History_Files/", 
                    pattern="*)_Merged.txt", full.names=FALSE, recursive=FALSE)

trip_route_plot <- function(f){
    # get the truck driver info for plot title
    title <- str_replace(f, "History_", "")
    title <- str_remove(title, ".xlsx_Merged")
    # load in the data
    data <- read.table(f, sep = "\t")
    # select only long trips, format longitude, latitude etc
    trip <- filter(data, str_detect(V13, "LongTrip"))
    trip <- select(trip, V1, V2, V5, V9, V14)
    trip <- separate(trip, V9, into = c("longitude", "latitude"), sep = ",")
    trip <- separate(trip, V1, into = c("LP", "date"), sep = "-")
    trip$latitude <- as.numeric(trip$latitude)
    trip$longitude <- as.numeric(trip$longitude)
    trip$V14 <- as.numeric(trip$V14)
    trip$V2 <- dmy_hms(trip$V2)
    # half hour aggregate steps
    trip$halfhour <- cut(trip$V2, breaks = "30 min")
    trip <- group_by(trip, halfhour)
    half.hour.aggregate <- summarise(trip, across(matches("V5|longitude|latitude|V14"), mean), 
                             across(matches("date"), unique))
    half.hour.aggregate <- rename(half.hour.aggregate, Speed = V5, TripNumber = V14)
    # Generate labels for facet plot
    label <- paste0("TripNum", unique(as.character(half.hour.aggregate$TripNumber)), " - Start_Date:", unique(as.character(half.hour.aggregate$date)))
    label <- setNames(label, unique(half.hour.aggregate$TripNumber))
    # create plot object
    g <- ggplot(half.hour.aggregate, aes(x = longitude, y = latitude, colour = Speed, size = 1/Speed))+
        geom_point()+
        theme_bw()+
        ggtitle(title)+
        scale_color_viridis(alpha = 0.3)+
        coord_fixed()+
        ylim(-26.6,-15)+
        xlim(25,31.5)+
        geom_point(aes(x=28.2525, y=-26.1689), colour="black", shape = 2, size = 2)+ #Net
        geom_point(aes(x=29.9886, y=-22.2116), colour="black", shape = 0, size = 8)+ #Beitbridge
        geom_point(aes(x=25.2679, y=-17.7898), colour="black", shape = 0, size = 8)+ #Kazungula
        geom_point(aes(x=27.9469, y=-23.0008), colour="black", shape = 0, size = 8)+ #Groblersbrug
        geom_point(aes(x=30.8342, y=-20.0722), colour="black", shape = 1, size = 4)+ #Masvingo
        geom_point(aes(x=29.4495, y=-23.9096), colour="black", shape = 1, size = 4)+ #Polokwane
        geom_point(aes(x=31.4296, y=-19.9606), colour="black", shape = 5, size = 4)+ #Bikita Mine
        geom_point(aes(x=31.3276, y=-17.3043), colour="black", shape = 5, size = 4)+ #Trojan Mine
        geom_point(aes(x=31.3132, y=-17.3026), colour="black", shape = 5, size = 4)+ #Freda Rebecca Mine
        geom_point(aes(x=31.3008, y=-26.5107), colour="black", shape = 6, size = 4)+ #Pal Fridge
        geom_point(aes(x=29.8216, y=-18.9192), colour="black", shape = 6, size = 4)+ #Colbro Kwekwe
        geom_point(aes(x=30.9751, y=-17.8719), colour="black", shape = 6, size = 4)+ #Colbro Transport
        geom_point(aes(x=28.5627, y=-20.1738), colour="black", shape = 6, size = 4) #Colbro (Bulawayo)
        #facet_wrap(~TripNumber, ncol = 10, labeller = as_labeller(label))
    gg <- ggplot(half.hour.aggregate, aes(x = longitude, y = latitude, colour = Speed, size = 1/Speed))+
        geom_point()+
        theme_bw()+
        ggtitle(title)+
        scale_color_viridis(alpha = 0.3)+
        coord_fixed()+
        ylim(-26.6,-15)+
        xlim(25,31.5)+
        geom_point(aes(x=28.2525, y=-26.1689), colour="black", shape = 2, size = 2)+ #Net
        geom_point(aes(x=29.9886, y=-22.2116), colour="black", shape = 0, size = 8)+ #Beitbridge
        geom_point(aes(x=25.2679, y=-17.7898), colour="black", shape = 0, size = 8)+ #Kazungula
        geom_point(aes(x=27.9469, y=-23.0008), colour="black", shape = 0, size = 8)+ #Groblersbrug
        geom_point(aes(x=30.8342, y=-20.0722), colour="black", shape = 1, size = 4)+ #Masvingo
        geom_point(aes(x=29.4495, y=-23.9096), colour="black", shape = 1, size = 4)+ #Polokwane
        geom_point(aes(x=31.4296, y=-19.9606), colour="black", shape = 5, size = 4)+ #Bikita Mine
        geom_point(aes(x=31.3276, y=-17.3043), colour="black", shape = 5, size = 4)+ #Trojan Mine
        geom_point(aes(x=31.3132, y=-17.3026), colour="black", shape = 5, size = 4)+ #Freda Rebecca Mine
        geom_point(aes(x=31.3008, y=-26.5107), colour="black", shape = 6, size = 4)+ #Pal Fridge
        geom_point(aes(x=29.8216, y=-18.9192), colour="black", shape = 6, size = 4)+ #Colbro Kwekwe
        geom_point(aes(x=30.9751, y=-17.8719), colour="black", shape = 6, size = 4)+ #Colbro Transport
        geom_point(aes(x=28.5627, y=-20.1738), colour="black", shape = 6, size = 4)+ #Colbro (Bulawayo)
        facet_wrap(~TripNumber, ncol = 10, labeller = as_labeller(label))
    # save plot object to file
    ggsave(paste0(out, title, "_superimposed.png"), plot = g, height = 15, width = 10)
    ggsave(paste0(out, title, ".png"), plot = gg, height = 15, width = 25)
}

lapply(files, trip_route_plot)
