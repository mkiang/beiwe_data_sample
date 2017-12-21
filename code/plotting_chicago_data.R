## Imports ----
library(tidyverse)
library(lubridate)

## Helper functions ----
bash_merge <- function(folder, awk = TRUE, joined_file = "0000-merged.csv") {
    # Uses bash `awk` or `cat` to merge files. 
    # In general, faster than looping `fread()` for `read_csv`. 
    # Note: `cat` doesn't work if there is a header row.
    original_wd <- getwd()
    setwd(folder)
    if (awk){
        system(paste0("awk 'FNR==1 && NR!=1{next;}{print}' *.csv > ", 
                      joined_file))
    } else {
        system(paste0("cat *.csv > ", joined_file))
    }
    setwd(original_wd)
}

## Merge all gps files within each user ----
for (f in list.dirs('./data', recursive = FALSE)) {
    bash_merge(paste0(f, "/gps"))
}

## Now import all five merged files ----
all_users <- NULL
for (f in list.files("./", recursive = TRUE, pattern = "0000-merged.csv")) {
    all_gps <- rbind(all_gps, read_csv(f))
}

## Sort it and remove duplicates (none in the default case, but possible on 
## other data)
all_gps <- all_gps %>% 
    arrange(desc(timestamp)) %>% 
    distinct() %>% 
    ungroup()

## Remove the observations that are outside of the Chicago box we want
sub_gps <- all_gps %>%
    filter(longitude > -87.948500 & longitude < -87.595322,
           latitude  >  41.843991)

## Plot it
chicago_zoom <- get_map("chicago", source = "stamen", 
                        maptype = "toner-background", 
                        zoom = 14, color = "bw")
chicago_map <- ggmap(chicago_zoom, darken = c(.75, "white")) + 
    coord_fixed(1.3) +
    stat_binhex(data = sub_gps, 
                aes(x = longitude, y = latitude, fill = log10(..count..)), 
                alpha = .9, bins = 300) + 
    scale_fill_distiller("Observations", palette = "Spectral", breaks = 0:5, 
                         labels = c(expression(10^0), expression(10^1), 
                                    expression(10^2), expression(10^3), 
                                    expression(10^4), expression(10^5))) + 
    theme(axis.text = element_blank(), 
          axis.ticks = element_blank(), 
          legend.position = c(.99, .01), 
          legend.justification = c(1, 0), 
          legend.background = element_rect(fill = alpha("white", .8)), 
          legend.text = element_text(hjust = 0, vjust = 0)) +
    labs(x = NULL, y = NULL)

## Save
ggsave("./plots/chicago_map.pdf", chicago_map, 
       width = 5, height = 5, scale = 1.5) 
ggsave("./plots/chicago_map.jpg", chicago_map, dpi = 200,
       width = 5, height = 5, scale = 1.5) 
